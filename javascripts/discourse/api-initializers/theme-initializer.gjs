import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.8.0", (api) => {
  api.onPageChange((url) => {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera || "";
    const isMobile = /iPhone|iPad|iPod|Android/i.test(userAgent);
    const isFomioApp = userAgent.includes("FomioMobileApp");

    // Only run on mobile browsers outside the app webview
    if (!isMobile || isFomioApp) {
      return;
    }

    const pageText = (document.body?.innerText || "").toLowerCase();

    // CASE 1: Login page -> send to app sign in
    if (url === "/login") {
      showRedirectScreen(
        "🔐",
        "Continue in Fomio",
        "Opening the app for sign in...",
        "fomio://signin?autoAuth=true"
      );
      return;
    }

    // CASE 2: Signup completed -> show confirmation, then open app
    const isSignupPage = url === "/signup" || url.startsWith("/u/account-created");
    const hasActivationMessage =
      document.querySelector(".activation-required") ||
      document.querySelector(".account-created") ||
      pageText.includes("sent an activation") ||
      pageText.includes("check your email") ||
      pageText.includes("activation mail");

    if (isSignupPage && hasActivationMessage) {
      showRedirectScreen(
        "📧",
        "Check Your Email",
        "We sent you an activation link. Opening Fomio...",
        "fomio://awaiting-activation"
      );
      return;
    }

    // CASE 3: Account activation success -> open app
    const isActivationPage = url.includes("/u/activate-account/");
    const isActivationSuccess =
      document.querySelector(".account-activation-success") ||
      pageText.includes("your new account is confirmed") ||
      pageText.includes("account is confirmed");

    if (isActivationPage && isActivationSuccess) {
      showRedirectScreen(
        "🎉",
        "Account Activated!",
        "Opening Fomio...",
        "fomio://signin?autoAuth=true"
      );
    }
  });

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
