import { apiInitializer } from "discourse/lib/api";
import { settings } from "virtual:theme";

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
      }
      return;
    }

    // CASE 2: Activation link -> hand off token to app immediately
    const activationMatch = url.match(/^\/u\/activate-account\/([^/?]+)/);
    if (activationMatch) {
      const token = activationMatch[1];
      showRedirectScreen(
        "✉️",
        "Opening Fomio",
        "Activating your account…",
        `${appUrl}activate?token=${encodeURIComponent(token)}`
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
