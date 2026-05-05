import { apiInitializer } from "discourse/lib/api";
import getURL, { withoutPrefix } from "discourse/lib/get-url";

// Keep in sync with fomio-sidebar.gjs and isDiscourseAuthSupportingPath in
// theme-initializer.gjs. Discourse themes cannot share modules across files.
const AUTH_PATHS = [
  "/login",
  "/signup",
  "/session/",
  "/user-api-key",
  "/password-reset",
  "/u/activate-account",
  "/u/account-created",
  "/invites",
  "/u/confirm",
  "/auth/",
];

function isAuthPath(url) {
  return AUTH_PATHS.some((p) => url.startsWith(p));
}

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

/**
 * Toggles layout ownership classes based on whether the current URL is a
 * content page or an auth/Discourse-flow page.
 *
 * The CSS layer reads this class to:
 *   - Show/hide .fomio-sidebar and .fomio-bottom-bar
 *   - Suppress .sidebar-wrapper (native Discourse sidebar)
 *   - Collapse .d-header height on desktop
 *   - Apply 260px left offset to #main-outlet-wrapper
 */
export default apiInitializer("1.8.0", (api) => {
  function syncLayoutClasses() {
    const path = normalizeDiscoursePath(window.location.pathname);
    const authMode = isAuthPath(path);

    document.body.classList.toggle("fomio-auth-mode", authMode);
    document.body.classList.toggle("fomio-sidebar-active", !authMode);
  }

  syncLayoutClasses();

  api.onPageChange(() => {
    syncLayoutClasses();
  });
});
