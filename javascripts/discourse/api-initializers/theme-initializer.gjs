import { next } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import getURL, { withoutPrefix } from "discourse/lib/get-url";
import { settings, themePrefix } from "virtual:theme";
import {
  consumeAuthIntent,
  consumeAuthReturnContext,
  POST_LOGIN_OPEN_COMPOSER_KEY,
} from "../lib/fomio-auth-intent";
import {
  bookmarksPathForUser,
  profileSummaryPathForUser,
} from "../lib/fomio-mobile-nav-paths";

/**
 * theme-initializer.gjs — Mobile Web → App Handoff
 *
 * PURPOSE
 * -------
 * Detects mobile browsers (not the app webview) and returns users to the
 * Fomio app only at safe moments: after app-initiated signup activation completes,
 * never on ordinary home/latest visits. Desktop browsers are never touched.
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
 *     → Theme sets a short-lived sessionStorage expiry (app signup path only)
 *     → Theme shows handoff overlay → fomio://signin?autoAuth=true
 *     → App opens auth flow
 *
 *   No guards needed: signup browser never visits /login with redirectCount > 0,
 *   so sessionStorage flag is never set, and the post-activation home handoff fires.
 *
 * DIRECT /login TAP (email link on mobile)
 * -----------------------------------------
 *   User taps a link to meta.fomio.app/login in email or browser.
 *   Web login stays in-browser; use topic/footer CTAs or settings-driven links to open the app.
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
  const WEB_AUTH_INTENT_KEY = "fomio_web_auth_intent";
  /** App-initiated signup only: set on /u/activate-account, consumed on next home visit. */
  const POST_ACTIVATION_HANDOFF_EXPIRY_KEY = "fomio_post_activation_expires_at";
  const ACTIVATION_HANDOFF_TTL_MS = 10 * 60 * 1000;
  /** Direct mobile web sign-in: set on /login (no redirect, no explicit web intent), cleared on home after auth. */
  const MOBILE_SIGNIN_PENDING_KEY = "fomio_mobile_signin_pending";

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

  function hasExplicitWebAuthIntent() {
    try {
      return window.localStorage.getItem(WEB_AUTH_INTENT_KEY) === "1";
    } catch {
      return false;
    }
  }

  function setExplicitWebAuthIntent() {
    try {
      window.localStorage.setItem(WEB_AUTH_INTENT_KEY, "1");
    } catch {
      // Ignore storage failures and fall back to default handoff behavior.
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

  /**
   * After Fomio web login (`fomio_web=1`), consume session intent + return context here
   * (login UI uses peek only). `view_saved` → bookmarks; `view_profile` → profile summary;
   * `create_byte` uses return path + optional composer open.
   */
  function applyFomioWebAuthResume() {
    const intent = consumeAuthIntent();
    const returnPath = consumeAuthReturnContext();
    const router = api.container.lookup("service:router");
    const composer = api.container.lookup("service:composer");
    const user = api.getCurrentUser();

    const current = router
      ? (router.currentURL || "").split("?")[0]
      : normalizeDiscoursePath(window.location.pathname);

    if (intent === "view_saved") {
      const bookmarksPath = bookmarksPathForUser(user);
      if (bookmarksPath && bookmarksPath !== current) {
        window.location.assign(getURL(bookmarksPath));
      }
      return;
    }

    if (intent === "view_profile") {
      const profilePath = profileSummaryPathForUser(user);
      if (profilePath && profilePath !== current) {
        window.location.assign(getURL(profilePath));
      }
      return;
    }

    const openComposerIfNeeded = () => {
      if (intent !== "create_byte" || !composer) {
        return;
      }
      try {
        composer.openNewTopic();
      } catch (e) {
        console.warn("[Fomio] composer.openNewTopic after web auth failed", e);
      }
    };

    const target = returnPath ? returnPath.split("?")[0] : null;

    if (target && target !== current) {
      if (intent === "create_byte") {
        try {
          window.sessionStorage.setItem(POST_LOGIN_OPEN_COMPOSER_KEY, "1");
        } catch {
          // Ignore storage failures.
        }
      }
      window.location.assign(getURL(returnPath));
      return;
    }

    next(openComposerIfNeeded);
  }

  function drainPendingPostLoginComposer() {
    if (!api.getCurrentUser()) {
      return;
    }

    let shouldOpen = false;
    try {
      shouldOpen =
        window.sessionStorage.getItem(POST_LOGIN_OPEN_COMPOSER_KEY) === "1";
      if (shouldOpen) {
        window.sessionStorage.removeItem(POST_LOGIN_OPEN_COMPOSER_KEY);
      }
    } catch {
      return;
    }

    if (!shouldOpen) {
      return;
    }

    const composer = api.container.lookup("service:composer");
    if (!composer) {
      return;
    }

    next(() => {
      try {
        composer.openNewTopic();
      } catch (e) {
        console.warn(
          "[Fomio] composer.openNewTopic after web auth redirect failed",
          e
        );
      }
    });
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
  function showHandoffOverlay(deepLink) {
    removeHandoffOverlayIfPresent();

    const titleKey = "mobile_handoff.home_title";
    const subtitleKey = "mobile_handoff.home_subtitle";

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

    drainPendingPostLoginComposer();

    const path = normalizeDiscoursePath(rawPath);
    const searchParams = new URLSearchParams(window.location.search);
    const hasWebAuthParam = searchParams.get("fomio_web") === "1";
    const explicitWebAuthIntent =
      hasWebAuthParam || hasExplicitWebAuthIntent();

    if (hasWebAuthParam && (path === "/login" || path.startsWith("/signup"))) {
      setExplicitWebAuthIntent();
    }

    if (
      explicitWebAuthIntent &&
      api.getCurrentUser() &&
      !isDiscourseAuthSupportingPath(path) &&
      path !== "/login"
    ) {
      try {
        window.localStorage.removeItem(WEB_AUTH_INTENT_KEY);
      } catch {
        // Ignore storage failures.
      }
      applyFomioWebAuthResume();
    }

    const appUrl = settings.fomio_app_url || "fomio://";

    if (isDiscourseAuthSupportingPath(path)) {
      if (path.startsWith("/session/")) {
        markFomioAuthFlowIfRedirected();
      }
      if (path.startsWith("/signup")) {
        const params = new URLSearchParams(window.location.search);
        if (params.get("fomio") === "1") {
          sessionStorage.setItem("fomio_app_signup", "1");
        }
      }
      if (path.startsWith("/u/activate-account")) {
        if (sessionStorage.getItem("fomio_app_signup") === "1") {
          sessionStorage.removeItem("fomio_app_signup");
          sessionStorage.setItem(
            POST_ACTIVATION_HANDOFF_EXPIRY_KEY,
            String(Date.now() + ACTIVATION_HANDOFF_TTL_MS)
          );
        }
      }
      return;
    }

    // CASE 1: Login page
    // If arrived via server-side redirect (redirectCount > 0) we're inside the app's
    // User API Key auth flow (/user-api-key/new → /login). Set GUARD 1 so the home
    // handler (GUARD 2) skips the handoff — intercepting fomio://signin?autoAuth=true
    // inside the auth session would cancel it.
    // If it's a direct mobile web visit (no redirect, no explicit web intent) the user
    // is signing in via their browser. Mark it so the home handler can hand them off
    // to the app once Discourse confirms auth.
    if (path === "/login") {
      if (explicitWebAuthIntent) {
        return;
      }
      const navEntry = window.performance?.getEntriesByType?.("navigation")?.[0];
      const arrivedViaRedirect = navEntry && navEntry.redirectCount > 0;
      if (arrivedViaRedirect) {
        sessionStorage.setItem("fomio_auth_flow", "1");
      } else {
        sessionStorage.setItem(MOBILE_SIGNIN_PENDING_KEY, "1");
      }
      return;
    }

    // CASE 2: Home-like routes — hand off to the app after sign-in.
    // Three sub-cases:
    //   a) App-initiated signup activation (POST_ACTIVATION_HANDOFF_EXPIRY_KEY, TTL-guarded)
    //   b) Direct mobile web sign-in (MOBILE_SIGNIN_PENDING_KEY, only fires once user is authed)
    //   c) Ordinary logged-in browse → no redirect
    // GUARD 2: skip if we're mid User API Key auth session (GUARD 1 set fomio_auth_flow).
    const HOME_PATHS = new Set(["/", "/latest", "/new", "/top", "/categories"]);
    if (HOME_PATHS.has(path)) {
      if (sessionStorage.getItem("fomio_auth_flow") === "1") {
        sessionStorage.removeItem("fomio_auth_flow");
        return;
      }
      if (explicitWebAuthIntent) {
        return;
      }

      // Sub-case a: app-initiated signup activation handoff (TTL-bounded).
      const expiryRaw = sessionStorage.getItem(
        POST_ACTIVATION_HANDOFF_EXPIRY_KEY
      );
      if (expiryRaw) {
        const expiry = parseInt(expiryRaw, 10);
        if (!Number.isNaN(expiry) && Date.now() <= expiry) {
          sessionStorage.removeItem(POST_ACTIVATION_HANDOFF_EXPIRY_KEY);
          showHandoffOverlay(`${appUrl}signin?autoAuth=true`);
        } else {
          sessionStorage.removeItem(POST_ACTIVATION_HANDOFF_EXPIRY_KEY);
        }
        return;
      }

      // Sub-case b: direct mobile web sign-in — hand off once Discourse confirms the user.
      // The marker is set on /login (direct visit, no redirect). Guard against stale markers
      // left when the user visited /login but did not complete sign-in by requiring an
      // authenticated session before firing.
      if (
        sessionStorage.getItem(MOBILE_SIGNIN_PENDING_KEY) === "1" &&
        api.getCurrentUser()
      ) {
        sessionStorage.removeItem(MOBILE_SIGNIN_PENDING_KEY);
        showHandoffOverlay(`${appUrl}signin?autoAuth=true`);
        return;
      }

      return;
    }
  }

  /**
   * Signup (Screen 3): terracotta password-strength meter under the password field.
   * Discourse has no numeric strength API — width follows length/complexity heuristics.
   */
  function attachSignupPasswordStrength() {
    const path = normalizeDiscoursePath(window.location.pathname);
    if (!path.startsWith("/signup")) {
      return;
    }

    const run = () => {
      const info = document.querySelector(
        ".create-account__password .create-account__password-info"
      );
      const input = document.querySelector("#new-account-password");
      if (!info || !input || info.querySelector(".fomio-password-strength-bar")) {
        return;
      }

      const bar = document.createElement("div");
      bar.className = "fomio-password-strength-bar";
      bar.setAttribute("aria-hidden", "true");
      const fill = document.createElement("div");
      fill.className = "fomio-password-strength-bar__fill";
      bar.appendChild(fill);
      info.insertBefore(bar, info.firstChild);

      const score = (pw) => {
        if (!pw) {
          return 0;
        }
        let s = Math.min(72, (pw.length / 14) * 65);
        if (pw.length >= 8) {
          s = Math.max(s, 32);
        }
        if (pw.length >= 12) {
          s = Math.max(s, 48);
        }
        if (/[0-9]/.test(pw) && /[a-zA-Z]/.test(pw)) {
          s = Math.min(100, s + 14);
        }
        if (/[^a-zA-Z0-9]/.test(pw)) {
          s = Math.min(100, s + 10);
        }
        return Math.round(Math.min(100, s));
      };

      const onInput = () => {
        fill.style.width = `${score(input.value)}%`;
      };
      input.addEventListener("input", onInput);
      onInput();
    };

    requestAnimationFrame(() => requestAnimationFrame(run));
  }

  /**
   * Screen 6A (forgot-password modal): inline valid-email hint/check and
   * "Back to sign in" control in modal footer.
   */
  function enhanceForgotPasswordModal() {
    const modal = document.querySelector(".d-modal.forgot-password-modal");
    if (!modal) {
      return;
    }

    const body = modal.querySelector(".d-modal__body");
    const footer = modal.querySelector(".d-modal__footer");
    if (!body || !footer) {
      return;
    }

    const input = modal.querySelector("#username-or-email");
    if (!input) {
      modal.classList.add("fomio-forgot-success");

      if (!body.querySelector(".fomio-reset-success-icon")) {
        const icon = document.createElement("div");
        icon.className = "fomio-reset-success-icon";
        icon.setAttribute("aria-hidden", "true");
        body.prepend(icon);
      }

      if (!body.querySelector(".fomio-reset-success-heading")) {
        const heading = document.createElement("h2");
        heading.className = "fomio-reset-success-heading";
        heading.textContent = th("auth_password_reset.success_title");
        const bodyText = body.querySelector("p");
        if (bodyText) {
          body.insertBefore(heading, bodyText);
        } else {
          body.appendChild(heading);
        }
      }

      const successBody = body.querySelector("p");
      if (successBody) {
        successBody.classList.add("fomio-reset-success-body");
        successBody.textContent = th("auth_password_reset.success_body");
      }

      const actionButton = footer.querySelector(".btn-primary");
      if (actionButton) {
        actionButton.textContent = th("auth_password_reset.resend_reset_email");
        if (!actionButton.dataset.fomioResendBound) {
          actionButton.addEventListener(
            "click",
            (event) => {
              event.preventDefault();
              event.stopImmediatePropagation();
              modal.querySelector(".modal-close")?.click();
              requestAnimationFrame(() => {
                document.querySelector("#forgot-password-link")?.click();
              });
            },
            true
          );
          actionButton.dataset.fomioResendBound = "1";
        }
      }

      footer.querySelector(".btn:not(.btn-primary)")?.remove();

      let backLink = footer.querySelector(".fomio-forgot-back-link");
      if (!backLink) {
        const backLink = document.createElement("button");
        backLink.type = "button";
        backLink.className = "fomio-forgot-back-link";
        backLink.textContent = `\u2039 ${th("auth_password_reset.back_to_sign_in")}`;
        backLink.addEventListener("click", () => {
          modal.querySelector(".modal-close")?.click();
        });
        footer.appendChild(backLink);
        backLink = footer.querySelector(".fomio-forgot-back-link");
      }

      if (!footer.querySelector(".fomio-reset-success-divider")) {
        const divider = document.createElement("div");
        divider.className = "fomio-reset-success-divider";
        divider.setAttribute("aria-hidden", "true");
        if (backLink) {
          footer.insertBefore(divider, backLink);
        } else {
          footer.appendChild(divider);
        }
      }

      return;
    }

    modal.classList.remove("fomio-forgot-success");

    if (!body.querySelector(".fomio-forgot-valid-hint")) {
      const hint = document.createElement("p");
      hint.className = "fomio-forgot-valid-hint";
      hint.textContent = th("auth_password_reset.valid_hint");
      body.appendChild(hint);
    }

    if (!footer.querySelector(".fomio-forgot-back-link")) {
      const backLink = document.createElement("button");
      backLink.type = "button";
      backLink.className = "fomio-forgot-back-link";
      backLink.textContent = `\u2039 ${th("auth_password_reset.back_to_sign_in")}`;
      backLink.addEventListener("click", () => {
        modal.querySelector(".modal-close")?.click();
      });
      footer.appendChild(backLink);
    }

    if (!footer.querySelector(".fomio-forgot-spam-note")) {
      const spamNote = document.createElement("p");
      spamNote.className = "fomio-forgot-spam-note";
      spamNote.textContent = th("auth_password_reset.spam_note");
      const backLink = footer.querySelector(".fomio-forgot-back-link");
      if (backLink) {
        footer.insertBefore(spamNote, backLink);
      } else {
        footer.appendChild(spamNote);
      }
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const syncValidityState = () => {
      const isValid = emailRegex.test((input.value || "").trim());
      modal.classList.toggle("fomio-forgot-valid-email", isValid);
    };

    if (!input.dataset.fomioResetBound) {
      input.addEventListener("input", syncValidityState);
      input.addEventListener("blur", syncValidityState);
      input.dataset.fomioResetBound = "1";
    }

    syncValidityState();
  }

  /**
   * Screen 7A-1 (TOTP default): shape Discourse 2FA DOM into
   * icon + eyebrow + heading + code label + two switch links layout.
   */
  function enhanceSecondFactorTotp() {
    const root = document.querySelector("#second-factor");
    if (!root) {
      return;
    }

    const titleText = root.querySelector("h3")?.textContent?.toLowerCase() || "";
    const dotp = root.querySelector(".d-otp");
    const dotpSlots = Array.from(root.querySelectorAll(".d-otp-slot"));
    const otpInputs = Array.from(root.querySelectorAll("input")).filter(
      (input) => input.type !== "hidden"
    );
    const isLikelyTotpTitle =
      (titleText.includes("two-factor") || titleText.includes("authentication")) &&
      !titleText.includes("backup");
    const isTotp =
      dotpSlots.length > 0 ||
      otpInputs.length === 6 ||
      (otpInputs.length === 1 && isLikelyTotpTitle);
    if (!isTotp) {
      root.classList.remove("fomio-second-factor-totp");
      root.classList.remove("fomio-second-factor-single");
      root
        .querySelectorAll(".fomio-second-factor-heading, .fomio-second-factor-code-label, .fomio-second-factor-switches")
        .forEach((node) => node.remove());
      root.querySelector(".fomio-second-factor-faux-row")?.remove();
      return;
    }

    root.classList.add("fomio-second-factor-totp");

    let otpGrid = root.querySelector(".fomio-second-factor-otp-grid");
    if (!otpGrid) {
      if (dotp) {
        otpGrid = dotp.querySelector(".d-otp-group");
      } else {
        const tokenContainer = root.querySelector(".second-factor-token-input");
        if (tokenContainer && tokenContainer.querySelectorAll("input").length > 1) {
          otpGrid = tokenContainer;
        } else if (otpInputs[0]?.parentElement) {
          otpGrid = otpInputs[0].parentElement;
        }
      }
    }
    if (!otpGrid) {
      return;
    }

    const isSingleInputTotp = !dotp && otpInputs.length === 1;
    root.classList.toggle("fomio-second-factor-single", isSingleInputTotp);

    if (dotp) {
      otpGrid.classList.add("fomio-second-factor-otp-grid");
      dotpSlots.forEach((slot) => slot.classList.add("fomio-second-factor-otp-box"));

      const dotpInput = dotp.querySelector(".d-otp-input");
      if (dotpInput) {
        dotpInput.classList.add("fomio-second-factor-dotp-input");
      }

      root.querySelector(".fomio-second-factor-faux-row")?.remove();
    } else if (isSingleInputTotp) {
      const input = otpInputs[0];
      input.classList.add("fomio-second-factor-single-input");

      let fauxRow = root.querySelector(".fomio-second-factor-faux-row");
      if (!fauxRow) {
        fauxRow = document.createElement("div");
        fauxRow.className = "fomio-second-factor-faux-row";
        for (let i = 0; i < 6; i += 1) {
          const box = document.createElement("div");
          box.className = "fomio-second-factor-faux-box";
          box.setAttribute("aria-hidden", "true");
          fauxRow.appendChild(box);
        }
        otpGrid.insertBefore(fauxRow, input);
      }

      const syncFauxBoxes = () => {
        const chars = (input.value || "").replace(/[^0-9]/g, "").slice(0, 6).split("");
        const boxes = fauxRow.querySelectorAll(".fomio-second-factor-faux-box");
        boxes.forEach((box, idx) => {
          box.textContent = chars[idx] || "";
          box.classList.toggle("is-active", idx === Math.min(chars.length, 5));
        });
      };

      if (!input.dataset.fomioSecondFactorBound) {
        input.addEventListener("input", syncFauxBoxes);
        input.addEventListener("focus", syncFauxBoxes);
        input.addEventListener("blur", syncFauxBoxes);
        fauxRow.addEventListener("click", () => input.focus());
        input.dataset.fomioSecondFactorBound = "1";
      }

      syncFauxBoxes();
    } else {
      otpGrid.classList.add("fomio-second-factor-otp-grid");
      otpInputs.forEach((input) => input.classList.add("fomio-second-factor-otp-box"));
      root.querySelector(".fomio-second-factor-faux-row")?.remove();
    }

    const title = root.querySelector("h3");
    if (title) {
      title.classList.add("fomio-second-factor-eyebrow");
      title.textContent = th("auth_second_factor.eyebrow");
    }

    if (!root.querySelector(".fomio-second-factor-heading")) {
      const heading = document.createElement("h2");
      heading.className = "fomio-second-factor-heading";
      heading.textContent = th("auth_second_factor.heading");
      if (title) {
        title.insertAdjacentElement("afterend", heading);
      } else {
        root.prepend(heading);
      }
    }

    const description = root.querySelector(".second-factor__description");
    if (description) {
      description.textContent = i18n("login.second_factor_description");
    }

    if (!root.querySelector(".fomio-second-factor-code-label")) {
      const codeLabel = document.createElement("p");
      codeLabel.className = "fomio-second-factor-code-label";
      codeLabel.textContent = th("auth_second_factor.code_label");
      otpGrid.insertAdjacentElement("beforebegin", codeLabel);
    }

    const toggle = root.querySelector(".toggle-second-factor-method");
    if (toggle) {
      toggle.textContent = th("auth_second_factor.use_backup_instead");

      let switches = root.querySelector(".fomio-second-factor-switches");
      if (!switches) {
        switches = document.createElement("div");
        switches.className = "fomio-second-factor-switches";
        root.appendChild(switches);
      }

      if (!switches.contains(toggle)) {
        switches.appendChild(toggle);
      }

      if (!switches.querySelector(".fomio-second-factor-passkey-link")) {
        const passkeyLink = document.createElement("a");
        passkeyLink.href = "#";
        passkeyLink.className =
          "fomio-second-factor-switch-link fomio-second-factor-passkey-link";
        passkeyLink.textContent = th("auth_second_factor.use_passkey_instead");
        passkeyLink.addEventListener("click", (event) => {
          event.preventDefault();
          const passkeyTrigger = document.querySelector(
            "#security-key-authenticate-button, .passkey-login-button .btn, .passkey-login-button button"
          );
          passkeyTrigger?.click();
        });
        switches.prepend(passkeyLink);
      }
    }
  }

  /**
   * Screen 7C-1 (backup code default): backup-focused content hierarchy with
   * key icon, warning pill, support note, active CTA, and switch links.
   */
  function enhanceSecondFactorBackupCode() {
    const root = document.querySelector("#second-factor");
    if (!root) {
      return;
    }

    const title = root.querySelector("h3");
    const titleText = title?.textContent?.toLowerCase() || "";
    const isBackupMode = titleText.includes("backup");
    const backupInput = Array.from(root.querySelectorAll("input")).find(
      (input) => input.type !== "hidden"
    );
    const submitButton = root.querySelector("#login-button, .btn-primary");

    if (!isBackupMode || !backupInput || !title) {
      root.classList.remove("fomio-second-factor-backup");
      const switches = root.querySelector(".fomio-backup-code-switches");
      const toggle = switches?.querySelector(".toggle-second-factor-method");
      if (toggle) {
        if (toggle.dataset.fomioBackupOriginalLabel) {
          toggle.textContent = toggle.dataset.fomioBackupOriginalLabel;
        }
        root.appendChild(toggle);
      }
      switches?.remove();

      root
        .querySelectorAll(
          ".fomio-backup-code-heading, .fomio-backup-code-label, .fomio-backup-code-warning, .fomio-backup-code-support"
        )
        .forEach((node) => node.remove());
      backupInput?.classList.remove("fomio-backup-code-input");

      if (submitButton && submitButton.dataset.fomioBackupOriginalLabel) {
        submitButton.textContent = submitButton.dataset.fomioBackupOriginalLabel;
        delete submitButton.dataset.fomioBackupOriginalLabel;
      }

      return;
    }

    root.classList.add("fomio-second-factor-backup");
    root.classList.remove("fomio-second-factor-totp");
    root.classList.remove("fomio-second-factor-single");
    root.querySelector(".fomio-second-factor-faux-row")?.remove();

    title.textContent = th("auth_second_factor.backup_eyebrow");

    if (!root.querySelector(".fomio-backup-code-heading")) {
      const heading = document.createElement("h2");
      heading.className = "fomio-backup-code-heading";
      heading.textContent = th("auth_second_factor.backup_heading");
      title.insertAdjacentElement("afterend", heading);
    }

    const description = root.querySelector(".second-factor__description");
    if (description) {
      description.textContent = th("auth_second_factor.backup_subtext");
    }

    const inputContainer = root.querySelector(".second-factor-token-input");
    const inputMount =
      inputContainer && inputContainer.tagName !== "INPUT"
        ? inputContainer
        : backupInput.parentElement;
    if (!inputMount) {
      return;
    }

    backupInput.classList.add("fomio-backup-code-input");
    backupInput.setAttribute("placeholder", th("auth_second_factor.backup_placeholder"));
    backupInput.setAttribute("autocapitalize", "none");
    backupInput.setAttribute("autocomplete", "one-time-code");
    backupInput.setAttribute("spellcheck", "false");

    const formatBackupCode = (rawValue) => {
      const chars = (rawValue || "")
        .replace(/[^a-zA-Z0-9]/g, "")
        .toLowerCase()
        .split("");
      let formatted = "";
      chars.forEach((char, index) => {
        formatted += char;
        if ((index + 1) % 4 === 0) {
          formatted += "-";
        }
      });
      return formatted;
    };

    if (!backupInput.dataset.fomioBackupCodeFormatBound) {
      backupInput.addEventListener("input", () => {
        backupInput.value = formatBackupCode(backupInput.value);
      });
      backupInput.dataset.fomioBackupCodeFormatBound = "1";
    }

    if (!backupInput.dataset.fomioBackupCodePreviewSeeded && !backupInput.value.trim()) {
      backupInput.value = "a3f9-";
      backupInput.dataset.fomioBackupCodePreviewSeeded = "1";
      requestAnimationFrame(() => {
        backupInput.focus();
        const caretPosition = backupInput.value.length;
        backupInput.setSelectionRange(caretPosition, caretPosition);
      });
    }

    if (!root.querySelector(".fomio-backup-code-label")) {
      const codeLabel = document.createElement("p");
      codeLabel.className = "fomio-backup-code-label";
      codeLabel.textContent = th("auth_second_factor.backup_code_label");
      inputMount.insertAdjacentElement("beforebegin", codeLabel);
    }

    if (!root.querySelector(".fomio-backup-code-warning")) {
      const warning = document.createElement("p");
      warning.className = "fomio-backup-code-warning";

      const icon = document.createElement("span");
      icon.className = "fomio-backup-code-warning__icon";
      icon.setAttribute("aria-hidden", "true");
      icon.textContent = "\u26A0";

      const text = document.createElement("span");
      text.textContent = th("auth_second_factor.backup_warning");

      warning.append(icon, text);
      inputMount.insertAdjacentElement("afterend", warning);
    }

    if (!root.querySelector(".fomio-backup-code-support")) {
      const support = document.createElement("p");
      support.className = "fomio-backup-code-support";

      const prefix = document.createElement("span");
      prefix.textContent = `${th("auth_second_factor.backup_lost_codes")} `;

      const link = document.createElement("a");
      link.href = "/about";
      link.className = "fomio-backup-code-support-link";
      link.textContent = th("auth_second_factor.backup_contact_support");

      support.append(prefix, link);
      const warning = root.querySelector(".fomio-backup-code-warning");
      if (warning) {
        warning.insertAdjacentElement("afterend", support);
      } else {
        inputMount.insertAdjacentElement("afterend", support);
      }
    }

    if (submitButton) {
      if (!submitButton.dataset.fomioBackupOriginalLabel) {
        submitButton.dataset.fomioBackupOriginalLabel = submitButton.textContent?.trim() || "";
      }
      submitButton.textContent = th("auth_second_factor.verify_backup_code");
    }

    const toggle = root.querySelector(".toggle-second-factor-method");
    if (toggle) {
      if (!toggle.dataset.fomioBackupOriginalLabel) {
        toggle.dataset.fomioBackupOriginalLabel = toggle.textContent?.trim() || "";
      }
      toggle.textContent = th("auth_second_factor.use_authenticator_instead");

      let switches = root.querySelector(".fomio-backup-code-switches");
      if (!switches) {
        switches = document.createElement("div");
        switches.className = "fomio-second-factor-switches fomio-backup-code-switches";
        root.appendChild(switches);
      }

      if (!switches.contains(toggle)) {
        switches.appendChild(toggle);
      }

      if (!switches.querySelector(".fomio-backup-code-passkey-link")) {
        const passkeyLink = document.createElement("a");
        passkeyLink.href = "#";
        passkeyLink.className =
          "fomio-second-factor-switch-link fomio-backup-code-passkey-link";
        passkeyLink.textContent = th("auth_second_factor.use_passkey_instead");
        passkeyLink.addEventListener("click", (event) => {
          event.preventDefault();
          const passkeyTrigger = document.querySelector(
            "#security-key-authenticate-button, .passkey-login-button .btn, .passkey-login-button button"
          );
          passkeyTrigger?.click();
        });
        switches.appendChild(passkeyLink);
      }
    }
  }

  /**
   * Screen 7B-2 (passkey loading): after CTA tap, keep card UI stable and
   * show a loading label/spinner while native biometric prompt is in flight.
   */
  function enhanceSecondFactorPasskeyLoading() {
    const root = document.querySelector("#second-factor");
    if (!root) {
      return;
    }

    const passkeyButton = root.querySelector(
      "#security-key-authenticate-button, .passkey-login-button .btn, .passkey-login-button button"
    );
    if (!passkeyButton || passkeyButton.dataset.fomioPasskeyLoadingBound === "1") {
      return;
    }

    passkeyButton.addEventListener("click", () => {
      if (passkeyButton.classList.contains("fomio-passkey-loading")) {
        return;
      }

      passkeyButton.classList.add("fomio-passkey-loading");
      passkeyButton.setAttribute("aria-busy", "true");

      const existingIcon = passkeyButton.querySelector(".d-icon");
      if (existingIcon) {
        existingIcon.setAttribute("aria-hidden", "true");
      }

      let spinner = passkeyButton.querySelector(".fomio-passkey-loading-spinner");
      if (!spinner) {
        spinner = document.createElement("span");
        spinner.className = "fomio-passkey-loading-spinner";
        spinner.setAttribute("aria-hidden", "true");
      }

      const labelText = th("auth_second_factor.waiting_for_authentication");
      const labelNode = passkeyButton.querySelector(".d-button-label");
      if (labelNode) {
        labelNode.textContent = labelText;
        labelNode.classList.add("fomio-passkey-loading-label");
        labelNode.insertAdjacentElement("beforebegin", spinner);
      } else {
        passkeyButton.textContent = "";
        const fallbackLabel = document.createElement("span");
        fallbackLabel.className = "fomio-passkey-loading-label";
        fallbackLabel.textContent = labelText;
        passkeyButton.append(spinner, fallbackLabel);
      }
    });

    passkeyButton.dataset.fomioPasskeyLoadingBound = "1";
  }

  // Run immediately on initializer load — catches fresh page loads from email link taps
  // (onPageChange alone is insufficient: it hooks into Ember's router, which fires
  // after the initial render, giving users a window to interact with the Discourse page)
  // showHandoffOverlay must be defined above before this runs (temporal dead zone).
  handleUrl(window.location.pathname);
  attachSignupPasswordStrength();
  enhanceForgotPasswordModal();
  enhanceSecondFactorTotp();
  enhanceSecondFactorBackupCode();
  enhanceSecondFactorPasskeyLoading();

  // Also handle subsequent Ember client-side navigations
  api.onPageChange(() => {
    handleUrl(window.location.pathname);
    attachSignupPasswordStrength();
    enhanceForgotPasswordModal();
    enhanceSecondFactorTotp();
    enhanceSecondFactorBackupCode();
    enhanceSecondFactorPasskeyLoading();
  });

  // Forgot-password modal and 2FA forms open without a route transition; observe DOM inserts.
  // Debounce so the callback only fires after Glimmer has finished its full render batch.
  // Without this, the observer fires between Ember run-loop frames while #second-factor is
  // still being rendered — our DOM moves (switches.appendChild(toggle)) land on elements
  // Glimmer is mid-reconcile, which prevents the 2FA form from becoming interactive.
  let observerDebounceTimer = null;
  const modalObserver = new MutationObserver(() => {
    clearTimeout(observerDebounceTimer);
    observerDebounceTimer = setTimeout(() => {
      enhanceForgotPasswordModal();
      enhanceSecondFactorTotp();
      enhanceSecondFactorBackupCode();
      enhanceSecondFactorPasskeyLoading();
    }, 50);
  });
  modalObserver.observe(document.body, { childList: true, subtree: true });
});
