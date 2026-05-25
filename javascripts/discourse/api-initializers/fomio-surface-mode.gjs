import { apiInitializer } from "discourse/lib/api";
import getURL, { withoutPrefix } from "discourse/lib/get-url";

const SURFACE_CLASS_BY_MODE = {
  expanded: "fomio-surface-expanded",
  "compact-desktop": "fomio-surface-compact-desktop",
  rail: "fomio-surface-rail",
  touch: "fomio-surface-touch",
};

const SURFACE_CLASSES = Object.values(SURFACE_CLASS_BY_MODE);
const READY_CLASS = "fomio-surface-ready";

// Keep in sync with auth/supporting path guards used by other Fomio initializers.
const AUTH_PATH_PREFIXES = [
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

function isAuthPath(rawPath) {
  const path = normalizeDiscoursePath(rawPath);
  return AUTH_PATH_PREFIXES.some((prefix) => path.startsWith(prefix));
}

function hasCoarsePointer() {
  return window.matchMedia("(pointer: coarse)").matches;
}

function hasNoHover() {
  return window.matchMedia("(hover: none)").matches;
}

function shortestViewportSide(width) {
  return Math.min(width, window.innerHeight || width);
}

function resolveSurfaceMode(width) {
  const coarseTouchDevice = hasCoarsePointer() && hasNoHover();
  const shortSide = shortestViewportSide(width);

  // Authoritative Fomio surface resolver:
  // keep touch ownership on phone-class devices in both portrait and
  // landscape. Tablet widths must stay on the rail/desktop shell so they
  // don't fall back to native header behavior when Discourse is not applying
  // the mobile theme surface.
  if (coarseTouchDevice && shortSide < 640) {
    return "touch";
  }

  if (width < 640) {
    return "touch";
  }

  if (width >= 1280) {
    return "expanded";
  }
  if (width >= 1024) {
    return "compact-desktop";
  }
  if (width >= 640) {
    return "rail";
  }
  return "touch";
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
}

export default apiInitializer("1.8.0", (api) => {
  // This file is the authoritative surface mode resolver for Fomio Web.
  // It only owns fomio-surface-* classes and intentionally does not touch:
  // - fomio-sidebar-active (owned by fomio-layout.gjs)
  // - fomio-auth-mode (owned by fomio-layout.gjs)
  let activeMode = null;
  let debounceTimer = null;

  const pointerQuery = window.matchMedia("(pointer: coarse)");
  const hoverQuery = window.matchMedia("(hover: none)");

  function syncSurfaceMode() {
    if (!document.body) {
      return;
    }

    if (isAuthPath(window.location.pathname)) {
      activeMode = null;
      clearSurfaceModeClasses();
      return;
    }

    const nextMode = resolveSurfaceMode(window.innerWidth);
    if (nextMode === activeMode) {
      // Ensure ready class is restored if another script removed it.
      document.body.classList.add(READY_CLASS);
      return;
    }

    activeMode = nextMode;
    applySurfaceModeClasses(nextMode);
  }

  function scheduleSync() {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(() => {
      syncSurfaceMode();
    }, 100);
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
