import { apiInitializer } from "discourse/lib/api";
import { settings } from "virtual:theme";

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
 *     On /login, performance.getEntriesByType('navigation')[0].redirectCount > 0
 *     means Discourse server-redirected us here from /user-api-key/new.
 *     We must NOT fire the /login redirect or the auth session catches
 *     fomio://signin?autoAuth=true (wrong URL, no payload) → "Authorization cancelled".
 *     Instead we set sessionStorage['fomio_auth_flow'] = '1'.
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
 *   Discourse login redirect:  app/controllers/user_api_keys_controller.rb:32
 *   App auth session:          apps/mobile/lib/auth.ts signIn()
 *   App deep link table:       apps/mobile/lib/deep-linking.ts
 */
export default apiInitializer("1.8.0", (api) => {
  function handleUrl(url) {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera || "";
    const isMobile = /iPhone|iPad|iPod|Android/i.test(userAgent);
    const isFomioApp = userAgent.includes("FomioMobileApp");

    // Only run on mobile browsers outside the app webview
    if (!isMobile || isFomioApp) {
      return;
    }

    const appUrl = settings.fomio_app_url || "fomio://";

    // CASE 1: Login page -> send to app sign in
    // Guard: skip if we arrived here via a server-side redirect (redirectCount > 0).
    // When the app's auth flow opens /user-api-key/new and the user isn't logged in
    // on the web, Discourse 302-redirects to /login. We must not intercept that redirect
    // or it interrupts ASWebAuthenticationSession / Chrome Custom Tabs, causing the
    // auth payload to never reach the app and sign-in to silently fail.
    if (url === "/login") {
      const navEntry = window.performance?.getEntriesByType?.("navigation")?.[0];
      const arrivedViaRedirect = navEntry && navEntry.redirectCount > 0;
      if (!arrivedViaRedirect) {
        showRedirectScreen(
          "🔐",
          "Continue in Fomio",
          "Opening the app for sign in...",
          `${appUrl}signin?autoAuth=true`
        );
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
    if (HOME_PATHS.has(url)) {
      if (sessionStorage.getItem("fomio_auth_flow") === "1") {
        sessionStorage.removeItem("fomio_auth_flow");
        return;
      }
      showRedirectScreen(
        "🎉",
        "Account Ready!",
        "Opening Fomio…",
        `${appUrl}signin?autoAuth=true`
      );
      return;
    }
  }

  // Run immediately on initializer load — catches fresh page loads from email link taps
  // (onPageChange alone is insufficient: it hooks into Ember's router, which fires
  // after the initial render, giving users a window to interact with the Discourse page)
  handleUrl(window.location.pathname);

  // Also handle subsequent Ember client-side navigations
  api.onPageChange(handleUrl);

  function showRedirectScreen(emoji, title, subtitle, deepLink) {
    document.body.innerHTML = `
      <div style="
        display:flex;
        flex-direction:column;
        align-items:center;
        justify-content:center;
        height:100vh;
        text-align:center;
        font-family:-apple-system, sans-serif;
        padding:20px;
        background:#fff;
      ">
        <div style="font-size:48px; margin-bottom:16px;">${emoji}</div>
        <h1 style="font-size:24px; margin-bottom:10px;">${title}</h1>
        <p style="font-size:16px; color:#666; margin-bottom:20px;">${subtitle}</p>
        <div style="
          width:40px;
          height:40px;
          border:3px solid #eee;
          border-top-color:#009688;
          border-radius:50%;
          animation:spin 1s linear infinite;
        "></div>
        <style>@keyframes spin { to { transform: rotate(360deg); } }</style>

        <p style="font-size:14px; color:#999; margin-top:30px;">
          Not opening? <a href="${deepLink}" style="color:#009688;">Tap here</a>
        </p>
      </div>
    `;

    setTimeout(() => {
      window.location.href = deepLink;
    }, 1200);
  }
});
