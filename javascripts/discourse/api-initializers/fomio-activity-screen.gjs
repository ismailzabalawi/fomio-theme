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

export default apiInitializer("1.8.0", (api) => {
  applyActivityScreenClasses();
  api.onPageChange(applyActivityScreenClasses);
});
