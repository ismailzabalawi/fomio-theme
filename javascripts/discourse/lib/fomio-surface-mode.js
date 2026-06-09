export const FOMIO_TOUCH_MAX_WIDTH = 767;
export const FOMIO_RAIL_MIN_WIDTH = 768;
export const FOMIO_COMPACT_DESKTOP_MIN_WIDTH = 1024;
export const FOMIO_EXPANDED_MIN_WIDTH = 1280;
export const TOUCH_SHELL_OPEN_CLASS = "fomio-mobile-sidebar-open";
export const DESKTOP_MASTER_PANE_OPEN_CLASS = "fomio-master-pane-rail-open";

export function shortestViewportSide(width, height = width) {
  return Math.min(width, height);
}

export function isTouchViewportWidth(width) {
  return width <= FOMIO_TOUCH_MAX_WIDTH;
}

export function isTouchSurfaceMode(mode) {
  return mode === "touch";
}

export function reconcileFomioSurfaceState(classList, previousMode, nextMode) {
  if (!previousMode || previousMode === nextMode) {
    return;
  }

  if (isTouchSurfaceMode(previousMode) === isTouchSurfaceMode(nextMode)) {
    return;
  }

  classList.remove(TOUCH_SHELL_OPEN_CLASS);
  classList.remove(DESKTOP_MASTER_PANE_OPEN_CLASS);
}

export function resolveFomioSurfaceMode({
  width,
  height = width,
  coarsePointer = false,
  noHover = false,
}) {
  const coarseTouchDevice = coarsePointer && noHover;
  const shortSide = shortestViewportSide(width, height);

  if (coarseTouchDevice && shortSide <= FOMIO_TOUCH_MAX_WIDTH) {
    return "touch";
  }

  if (isTouchViewportWidth(width)) {
    return "touch";
  }

  if (width >= FOMIO_EXPANDED_MIN_WIDTH) {
    return "expanded";
  }

  if (width >= FOMIO_COMPACT_DESKTOP_MIN_WIDTH) {
    return "compact-desktop";
  }

  if (width >= FOMIO_RAIL_MIN_WIDTH) {
    return "rail";
  }

  return "touch";
}
