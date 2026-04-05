import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import getURL, { withoutPrefix } from "discourse/lib/get-url";
import { settings, themePrefix } from "virtual:theme";

/**
 * theme-initializer.gjs — Mobile Web → App Handoff
 *
 * PURPOSE
 * -------
 * Detects mobile browsers (not the app webview) and redirects them to the
 * Fomio app via deep links at the right moment in the auth/signup flow.
 * Desktop browsers are never touched.
 *
 * DETECTION
 * ---------
 * Runs on every page load and every Ember client-side navigation.
 * - isMobile: UA contains iPhone/iPad/iPod/Android
 * - isFomioApp: UA contains "FomioMobileApp" (webview skip)
 *
 * SIGN-IN FLOW (app uses WebBrowser.openAuthSessionAsync)
 * -------------------------------------------------------
 *   App opens /user-api-key/new
 *     → Discourse 302s to /login      (user not logged in on web)
 *     → User logs in on Discourse web
 *     → Discourse redirects to /      (home — post-login default)
 *     → Discourse navigates back to /user-api-key/new
 *     → User taps "Authorize"
 *     → Discourse redirects to fomio://auth_redirect?payload=...
 *     → ASWebAuthenticationSession / Chrome Custom Tab catches it
 *     → lib/auth.ts decrypts payload, stores API key
 *
 *   GUARD 1 — redirectCount:
 *     On /login (local login) or /session/* (SSO, 2FA, OTP, passkeys, etc.),
 *     performance.getEntriesByType('navigation')[0].redirectCount > 0 means
 *     Discourse server-redirected us here (e.g. from /user-api-key/new → /login
 *     or → /session/sso when DiscourseConnect is enabled).
 *     We must NOT fire the /login “open app” redirect or the auth session catches
 *     fomio://signin?autoAuth=true (wrong URL, no payload) → "Authorization cancelled".
 *     Instead we set sessionStorage['fomio_auth_flow'] = '1' where applicable.
 *
 *   Paths under /session/, /user-api-key, /signup, password-reset, activation:
 *     Never show the handoff overlay or fire app deep links — finish in-browser.
 *   Handoff UI: locales/en.yml (mobile_handoff.*) + common.scss (.fomio-mobile-handoff).
 *
 *   GUARD 2 — sessionStorage flag:
 *     On home (/), we check for the flag set by GUARD 1. If present,
 *     this home visit is the post-login redirect inside the auth session —
 *     skip the redirect and clear the flag. The auth session continues to
 *     /user-api-key/new and completes normally.
 *
 * SIGN-UP FLOW (app uses WebBrowser.openBrowserAsync)
 * ----------------------------------------------------
 *   App opens /signup?fomio=1
 *     → User fills signup form
 *     → Discourse navigates to /u/account-created   ("check your email")
 *     → User opens email, taps activation link
 *     → Browser navigates to /u/activate-account/:token
 *     → Discourse renders page with "Activate Account" button
 *     → User clicks button (PUT /u/activate-account/:token.json)
 *     → Discourse JS does window.location.href = "/"
 *     → Browser lands on /
 *     → Theme fires → fomio://signin?autoAuth=true
 *     → App comes to foreground, user signs in
 *
 *   No guards needed: signup browser never visits /login with redirectCount > 0,
 *   so sessionStorage flag is never set, and the home redirect fires correctly.
 *
 * DIRECT /login TAP (email link on mobile)
 * -----------------------------------------
 *   User taps a link to meta.fomio.app/login in email or browser.
 *   redirectCount = 0 (direct navigation) → /login redirect fires → app sign-in.
 *
 * ⚠️  DO NOT REMOVE THE GUARDS ⚠️
 *   Removing GUARD 1 breaks sign-in: auth session catches wrong deep link.
 *   Removing GUARD 2 breaks sign-in: auth session catches home redirect deep link.
 *   Changing redirect URLs: must match deep-linking.ts route table in mobile app.
 *
 * DEEP LINKS USED
 * ---------------
 *   fomio://signin?autoAuth=true  → app/(auth)/signin.tsx (autoAuth triggers auth-modal)
 *
 * SOURCE VERIFIED AGAINST
 * -----------------------
 *   Discourse activation flow: frontend/discourse/app/templates/activate-account.gjs:84
 *   Discourse login redirect:  app/controllers/user_api_keys_controller.rb:26-33
 *   App auth session:          apps/mobile/lib/auth.ts signIn()
 *   App deep link table:       apps/mobile/lib/deep-linking.ts
 */
export default apiInitializer("1.8.0", (api) => {
  /**
   * Strip Discourse base_path (subfolder) and trailing slashes so /forum/login → /login.
   */
  function normalizeDiscoursePath(rawPath) {
    getURL("/");
    let path = withoutPrefix(rawPath);
    if (!path || path === "") {
      path = "/";
    }
    if (path.length > 1 && path.endsWith("/")) {
      path = path.slice(0, -1);
    }
    return path;
  }

  function markFomioAuthFlowIfRedirected() {
    const navEntry = window.performance?.getEntriesByType?.("navigation")?.[0];
    if (navEntry && navEntry.redirectCount > 0) {
      sessionStorage.setItem("fomio_auth_flow", "1");
    }
  }

  /**
   * Discourse routes where we must not show the handoff overlay or deep-link to the app.
   * (Authorize HTML is no_ember and does not load this script; this covers Ember routes.)
   */
  function isDiscourseAuthSupportingPath(path) {
    return (
      path.startsWith("/user-api-key") ||
      path.startsWith("/session/") ||
      path.startsWith("/password-reset") ||
      path.startsWith("/u/activate-account") ||
      path.startsWith("/u/account-created") ||
      path.startsWith("/signup") ||
      path.startsWith("/invites") ||
      path.startsWith("/u/confirm") ||
      path.startsWith("/auth/")
    );
  }

  const HANDOFF_ROOT_ID = "fomio-mobile-handoff-root";

  function th(key) {
    return i18n(themePrefix(key));
  }

  function removeHandoffOverlayIfPresent() {
    document.getElementById(HANDOFF_ROOT_ID)?.remove();
    document.documentElement.style.removeProperty("overflow");
    document.body.style.removeProperty("overflow");
  }

  /**
   * Full-viewport overlay (see common.scss .fomio-mobile-handoff).
   * Does not replace document.body — keeps Discourse DOM intact underneath.
   */
  function showHandoffOverlay(variant, deepLink) {
    removeHandoffOverlayIfPresent();

    const titleKey =
      variant === "login"
        ? "mobile_handoff.login_title"
        : "mobile_handoff.home_title";
    const subtitleKey =
      variant === "login"
        ? "mobile_handoff.login_subtitle"
        : "mobile_handoff.home_subtitle";

    const root = document.createElement("div");
    root.id = HANDOFF_ROOT_ID;
    root.className = "fomio-mobile-handoff";
    root.setAttribute("role", "dialog");
    root.setAttribute("aria-modal", "true");
    root.setAttribute("aria-labelledby", "fomio-mobile-handoff-title");

    const panel = document.createElement("div");
    panel.className = "fomio-mobile-handoff__panel";

    const eyebrow = document.createElement("p");
    eyebrow.className = "fomio-mobile-handoff__eyebrow";
    eyebrow.textContent = th("mobile_handoff.brand");

    const rule = document.createElement("div");
    rule.className = "fomio-mobile-handoff__rule";
    rule.setAttribute("aria-hidden", "true");

    const titleEl = document.createElement("h1");
    titleEl.id = "fomio-mobile-handoff-title";
    titleEl.className = "fomio-mobile-handoff__title";
    titleEl.textContent = th(titleKey);

    const subtitle = document.createElement("p");
    subtitle.className = "fomio-mobile-handoff__subtitle";
    subtitle.textContent = th(subtitleKey);

    const spinner = document.createElement("div");
    spinner.className = "fomio-mobile-handoff__spinner";
    spinner.setAttribute("aria-hidden", "true");

    const fallback = document.createElement("p");
    fallback.className = "fomio-mobile-handoff__fallback";
    fallback.appendChild(
      document.createTextNode(`${th("mobile_handoff.fallback_lead")} `)
    );
    const link = document.createElement("a");
    link.className = "fomio-mobile-handoff__link";
    link.href = deepLink;
    link.textContent = th("mobile_handoff.fallback_link");
    fallback.appendChild(link);

    panel.append(eyebrow, rule, titleEl, subtitle, spinner, fallback);
    root.appendChild(panel);

    document.documentElement.style.overflow = "hidden";
    document.body.style.overflow = "hidden";
    document.body.appendChild(root);

    setTimeout(() => {
      window.location.href = deepLink;
    }, 1200);
  }

  function handleUrl(rawPath) {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera || "";
    const isMobile = /iPhone|iPad|iPod|Android/i.test(userAgent);
    const isFomioApp = userAgent.includes("FomioMobileApp");

    // Only run on mobile browsers outside the app webview
    if (!isMobile || isFomioApp) {
      return;
    }

    const path = normalizeDiscoursePath(rawPath);

    const appUrl = settings.fomio_app_url || "fomio://";

    if (isDiscourseAuthSupportingPath(path)) {
      if (path.startsWith("/session/")) {
        markFomioAuthFlowIfRedirected();
      }
      return;
    }

    // CASE 1: Login page -> send to app sign in
    // Guard: skip if we arrived here via a server-side redirect (redirectCount > 0).
    // When the app's auth flow opens /user-api-key/new and the user isn't logged in
    // on the web, Discourse 302-redirects to /login. We must not intercept that redirect
    // or it interrupts ASWebAuthenticationSession / Chrome Custom Tabs, causing the
    // auth payload to never reach the app and sign-in to silently fail.
    if (path === "/login") {
      const navEntry = window.performance?.getEntriesByType?.("navigation")?.[0];
      const arrivedViaRedirect = navEntry && navEntry.redirectCount > 0;
      if (!arrivedViaRedirect) {
        showHandoffOverlay("login", `${appUrl}signin?autoAuth=true`);
      } else {
        // We're inside the sign-in auth flow (/user-api-key/new → /login).
        // After the user logs in, Discourse redirects to home before returning
        // to /user-api-key/new. Mark sessionStorage so the home redirect skips.
        sessionStorage.setItem("fomio_auth_flow", "1");
      }
      return;
    }

    // CASE 2: Home page -> redirect to app after signup or activation
    // Discourse navigates here (via window.location.href="/") after:
    //   a) successful account activation (activate-account.gjs:84)
    //   b) any other completion that lands on home
    // The user must complete the full web flow first:
    //   /signup → /u/account-created → /u/activate-account/:token
    //   → click "Activate Account" button → Discourse redirects to /
    // Only THEN do we send them to the app.
    // Guard: skip if we're mid sign-in auth flow (set on /login with redirectCount > 0).
    const HOME_PATHS = new Set(["/", "/latest", "/new", "/top", "/categories"]);
    if (HOME_PATHS.has(path)) {
      if (sessionStorage.getItem("fomio_auth_flow") === "1") {
        sessionStorage.removeItem("fomio_auth_flow");
        return;
      }
      showHandoffOverlay("home", `${appUrl}signin?autoAuth=true`);
      return;
    }
  }

  // Run immediately on initializer load — catches fresh page loads from email link taps
  // (onPageChange alone is insufficient: it hooks into Ember's router, which fires
  // after the initial render, giving users a window to interact with the Discourse page)
  // showHandoffOverlay must be defined above before this runs (temporal dead zone).
  handleUrl(window.location.pathname);

  // Also handle subsequent Ember client-side navigations
  api.onPageChange(handleUrl);
});
