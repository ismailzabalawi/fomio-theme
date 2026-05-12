import { isOwnUserSummarySurfacePath } from "./fomio-mobile-nav-paths";

export const FOMIO_ME_HUB_LANDING_SESSION_KEY = "fomio_me_hub_landing_v1";

export function armMeHubLandingForNextSummaryVisit() {
  try {
    sessionStorage.setItem(FOMIO_ME_HUB_LANDING_SESSION_KEY, "1");
  } catch {
    // ignore quota / private mode
  }
}

export function clearMeHubLandingSession() {
  try {
    sessionStorage.removeItem(FOMIO_ME_HUB_LANDING_SESSION_KEY);
  } catch {
    // ignore
  }
}

export function isMeHubLandingSessionArmed() {
  try {
    return sessionStorage.getItem(FOMIO_ME_HUB_LANDING_SESSION_KEY) === "1";
  } catch {
    return false;
  }
}

/**
 * Toggle body.fomio-me-hub-landing so touch SCSS can hide native Discourse summary
 * chrome until the user taps Summary in the Fomio hub (see common.scss).
 */
export function syncMeHubLandingBodyClass(path, currentUser) {
  if (typeof document === "undefined" || !document.body) {
    return;
  }
  const shouldLand =
    isMeHubLandingSessionArmed() &&
    isOwnUserSummarySurfacePath(path, currentUser);
  document.body.classList.toggle("fomio-me-hub-landing", shouldLand);
}
