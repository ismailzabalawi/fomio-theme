import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  clearPendingRailOverlay,
  PENDING_RAIL_OVERLAY_KEY,
} from "../javascripts/discourse/lib/fomio-rail-overlay-state.js";

describe("fomio-rail-overlay-state", () => {
  it("clears the pending rail overlay token", () => {
    const storage = {
      removedKey: null,
      removeItem(key) {
        this.removedKey = key;
      },
    };

    clearPendingRailOverlay(storage);

    assert.equal(storage.removedKey, PENDING_RAIL_OVERLAY_KEY);
  });

  it("is safe when session storage is unavailable", () => {
    assert.doesNotThrow(() => clearPendingRailOverlay(null));
  });
});
