import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  clearPendingMasterPaneOverlay,
  PENDING_MASTER_PANE_OVERLAY_KEY,
} from "../javascripts/discourse/lib/fomio-master-pane-overlay-state.js";

describe("fomio-master-pane-overlay-state", () => {
  it("clears the pending master pane overlay token", () => {
    const storage = {
      removedKey: null,
      removeItem(key) {
        this.removedKey = key;
      },
    };

    clearPendingMasterPaneOverlay(storage);

    assert.equal(storage.removedKey, PENDING_MASTER_PANE_OVERLAY_KEY);
  });

  it("is safe when session storage is unavailable", () => {
    assert.doesNotThrow(() => clearPendingMasterPaneOverlay(null));
  });
});
