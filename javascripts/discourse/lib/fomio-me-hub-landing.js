import { isOwnUserHubSurfacePath } from "./fomio-mobile-nav-paths";
import { shouldHideSharedProfileHeader } from "./fomio-profile-identity-ownership";
import { fomioCurrentPath } from "./fomio-router-pathname";

/**
 * Toggle body.fomio-me-hub-landing on the dedicated Me hub route so touch
 * SCSS can show the Fomio-owned hub instead of the native summary content.
 */
export function syncMeHubLandingBodyClass(path, currentUser) {
  if (typeof document === "undefined" || !document.body) {
    return;
  }
  const currentPath = fomioCurrentPath(path);
  const isTouchShell = Boolean(
    document.body.classList.contains("fomio-surface-touch")
  );
  const shouldLand = isOwnUserHubSurfacePath(currentPath, currentUser);
  const shouldHideSharedHeader = shouldHideSharedProfileHeader({
    currentPath,
    currentUser,
    isTouchShell,
  });
  document.body.classList.toggle("fomio-me-hub-landing", shouldLand);
  document.body.classList.toggle(
    "fomio-profile-identity-owned",
    shouldHideSharedHeader && !shouldLand
  );
}
