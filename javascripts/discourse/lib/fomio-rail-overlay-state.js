export const PENDING_RAIL_OVERLAY_KEY = "fomio_pending_rail_overlay_context";

export function clearPendingRailOverlay(storage = globalThis?.window?.sessionStorage) {
  storage?.removeItem?.(PENDING_RAIL_OVERLAY_KEY);
}

