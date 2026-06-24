import { apiInitializer } from "discourse/lib/api";
import {
  FOMIO_ACTIVITY_SCREEN_CLASS,
  FOMIO_ACTIVITY_SCREEN_VARIANT_CLASSES,
  fomioActivityRouteClass,
  fomioActivityRouteKind,
} from "../lib/fomio-activity-paths";

function currentUrl() {
  return window.location.pathname + window.location.search;
}

function applyActivityScreenClasses() {
  if (
    typeof document === "undefined" ||
    typeof window === "undefined" ||
    !document.body
  ) {
    return;
  }

  const kind = fomioActivityRouteKind(currentUrl());
  const currentVariantClasses = [...document.body.classList].filter((name) =>
    name.startsWith("fomio-activity-screen--")
  );

  document.body.classList.remove(
    FOMIO_ACTIVITY_SCREEN_CLASS,
    ...FOMIO_ACTIVITY_SCREEN_VARIANT_CLASSES,
    ...currentVariantClasses
  );

  if (kind) {
    document.body.classList.add(
      FOMIO_ACTIVITY_SCREEN_CLASS,
      fomioActivityRouteClass(currentUrl())
    );
  }
}

// Scroll the secondary activity nav so the active tab is horizontally centred.
// Uses double-rAF to run after Discourse has painted the updated active state.
function scrollActiveSecondaryTabIntoView() {
  if (typeof window === "undefined" || typeof document === "undefined") {
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      const active = document.querySelector(
        "#main-outlet .user-main .user-navigation.user-navigation-secondary ul.nav-pills [aria-current='location'] a, " +
        "#main-outlet .user-main .user-navigation.user-navigation-secondary ul.nav-pills a.active"
      );
      if (active) {
        active.scrollIntoView({ behavior: "instant", block: "nearest", inline: "center" });
      }
    });
  });
}

export default apiInitializer("1.8.0", (api) => {
  applyActivityScreenClasses();
  scrollActiveSecondaryTabIntoView();
  api.onPageChange(() => {
    applyActivityScreenClasses();
    scrollActiveSecondaryTabIntoView();
  });
});
