// Scroll-away rule for the mobile dock, from the archived theme's bar.
// The bar itself, its labels, and its colours stay in the theme component.

export const BAR_HIDE_START_Y = 120;
export const BAR_HIDE_DELTA_Y = 18;
export const BAR_SHOW_DELTA_Y = 10;
export const BAR_MIN_SCROLLABLE = 180;

export function nextBottomBarHidden({
  y,
  previousY,
  hidden,
  scrollableHeight,
  allowHide,
}) {
  if (!allowHide || scrollableHeight < BAR_MIN_SCROLLABLE) {
    return false;
  }

  const deltaY = y - previousY;
  if (y <= BAR_HIDE_START_Y) {
    return false;
  }
  if (deltaY >= BAR_HIDE_DELTA_Y) {
    return true;
  }
  if (deltaY <= -BAR_SHOW_DELTA_Y) {
    return false;
  }
  return hidden;
}
