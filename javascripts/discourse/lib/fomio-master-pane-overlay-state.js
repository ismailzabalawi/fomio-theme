export const PENDING_MASTER_PANE_OVERLAY_KEY =
  "fomio_pending_master_pane_overlay_context";

export function clearPendingMasterPaneOverlay(
  storage = globalThis?.window?.sessionStorage
) {
  storage?.removeItem?.(PENDING_MASTER_PANE_OVERLAY_KEY);
}
