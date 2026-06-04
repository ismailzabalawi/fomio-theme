const MENU_OFFSET = 18;
const TOOLBAR_HEIGHT = 48;
const VIEWPORT_OFFSET = 8;

export function getComposerSurfaceMode({
  hasFullscreenTopbar = false,
  replyControlClassName = "",
} = {}) {
  if (
    hasFullscreenTopbar ||
    replyControlClassName.includes("composer-action-create-topic") ||
    replyControlClassName.includes("composer-action-edit")
  ) {
    return "fullscreen";
  }

  if (replyControlClassName.includes("composer-action-reply")) {
    return "reply";
  }

  return "default";
}

export function computeComposerToolbarSafeTop({
  mode = "default",
  fullscreenTopbarBottom,
} = {}) {
  if (mode === "fullscreen" && fullscreenTopbarBottom) {
    return fullscreenTopbarBottom + VIEWPORT_OFFSET;
  }

  return VIEWPORT_OFFSET;
}

export function computeToolbarTriggerRect(start, end, safeTop = 0) {
  const left = Math.round((start.left + end.left) / 2);
  const selectionTop = Math.min(start.top, end.top);
  const selectionBottom = Math.max(start.bottom, end.bottom);
  const topAbove = selectionTop - MENU_OFFSET;
  const topBelow = selectionBottom + MENU_OFFSET;
  const topAboveToolbar = topAbove - TOOLBAR_HEIGHT - VIEWPORT_OFFSET;
  const top = topAboveToolbar < safeTop ? topBelow : topAbove;

  return {
    left,
    right: left,
    top,
    bottom: topBelow,
    width: 0,
    height: 0,
  };
}

export function computeToolbarViewportPosition(triggerRect, toolbarWidth, viewport) {
  const viewportWidth = viewport?.width ?? 0;
  let top = triggerRect.top === triggerRect.bottom
    ? triggerRect.bottom + VIEWPORT_OFFSET
    : triggerRect.top - TOOLBAR_HEIGHT - VIEWPORT_OFFSET;
  let left = triggerRect.left - toolbarWidth / 2;

  if (top < VIEWPORT_OFFSET) {
    top = triggerRect.bottom + VIEWPORT_OFFSET;
  }

  if (left < 0) {
    left = VIEWPORT_OFFSET;
  } else if (left + toolbarWidth > viewportWidth) {
    left = viewportWidth - toolbarWidth - VIEWPORT_OFFSET;
  }

  return { top, left };
}
