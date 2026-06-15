import { apiInitializer } from "discourse/lib/api";
import getURL, { withoutPrefix } from "discourse/lib/get-url";
import { isFomioShellPath } from "../lib/fomio-route-mode";
import {
  DESKTOP_MASTER_PANE_OPEN_CLASS,
  resolveFomioSurfaceMode,
  reconcileFomioSurfaceState,
  TOUCH_SHELL_OPEN_CLASS,
} from "../lib/fomio-surface-mode";

const SURFACE_CLASS_BY_MODE = {
  expanded: "fomio-surface-expanded",
  "compact-desktop": "fomio-surface-compact-desktop",
  rail: "fomio-surface-rail",
  touch: "fomio-surface-touch",
};

const SURFACE_CLASSES = Object.values(SURFACE_CLASS_BY_MODE);
const READY_CLASS = "fomio-surface-ready";

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

function hasCoarsePointer() {
  return window.matchMedia("(pointer: coarse)").matches;
}

function hasNoHover() {
  return window.matchMedia("(hover: none)").matches;
}

function applySurfaceModeClasses(mode) {
  const { classList } = document.body;

  classList.remove(...SURFACE_CLASSES);
  classList.add(SURFACE_CLASS_BY_MODE[mode]);
  classList.add(READY_CLASS);
}

function clearSurfaceModeClasses() {
  const { classList } = document.body;
  classList.remove(...SURFACE_CLASSES);
  classList.remove(READY_CLASS);
  classList.remove(TOUCH_SHELL_OPEN_CLASS);
  classList.remove(DESKTOP_MASTER_PANE_OPEN_CLASS);
}

export default apiInitializer("1.8.0", (api) => {
  // This file is the authoritative surface mode resolver for Fomio Web.
  // It only owns fomio-surface-* classes and intentionally does not touch:
  // - fomio-sidebar-active (owned by fomio-layout.gjs)
  // - fomio-auth-mode (owned by fomio-layout.gjs)
  let activeMode = null;

  const pointerQuery = window.matchMedia("(pointer: coarse)");
  const hoverQuery = window.matchMedia("(hover: none)");

  function syncSurfaceMode() {
    if (!document.body) {
      return;
    }

    if (!isFomioShellPath(normalizeDiscoursePath(window.location.pathname))) {
      activeMode = null;
      clearSurfaceModeClasses();
      return;
    }

    const nextMode = resolveFomioSurfaceMode({
      width: window.innerWidth,
      height: window.innerHeight || window.innerWidth,
      coarsePointer: hasCoarsePointer(),
      noHover: hasNoHover(),
    });
    if (nextMode === activeMode) {
      // Ensure ready class is restored if another script removed it.
      document.body.classList.add(READY_CLASS);
      return;
    }

    reconcileFomioSurfaceState(document.body.classList, activeMode, nextMode);
    activeMode = nextMode;
    applySurfaceModeClasses(nextMode);
  }

  function scheduleSync() {
    syncSurfaceMode();
  }

  syncSurfaceMode();

  api.onPageChange(() => {
    activeMode = null;
    scheduleSync();
  });

  window.addEventListener("resize", scheduleSync, { passive: true });
  window.addEventListener("orientationchange", scheduleSync, { passive: true });

  if (typeof pointerQuery.addEventListener === "function") {
    pointerQuery.addEventListener("change", scheduleSync);
    hoverQuery.addEventListener("change", scheduleSync);
  } else {
    // Safari fallback for environments that still expose addListener/removeListener.
    pointerQuery.addListener(scheduleSync);
    hoverQuery.addListener(scheduleSync);
  }
});
