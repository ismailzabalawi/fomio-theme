import { apiInitializer } from "discourse/lib/api";
import getURL, { withoutPrefix } from "discourse/lib/get-url";
import {
  isAuthPath,
  isDiscourseNativePath,
} from "../lib/fomio-route-mode";

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
    const discourseNativeMode = isDiscourseNativePath(path);
    const fomioShellMode = !authMode && !discourseNativeMode;

    document.body.classList.toggle("fomio-auth-mode", authMode);
    document.body.classList.toggle(
      "fomio-discourse-native-mode",
      discourseNativeMode
    );
    document.body.classList.toggle("fomio-sidebar-active", fomioShellMode);
    // Close the mobile sidebar on every navigation so it doesn't stay open
    // after the user taps a link inside it.
    document.body.classList.remove("fomio-mobile-sidebar-open");
    // Rail master pane overlay is transient UI and should never persist
    // across route changes.
    document.body.classList.remove("fomio-master-pane-rail-open");
  }

  syncLayoutClasses();

  api.onPageChange(() => {
    syncLayoutClasses();
  });
});
