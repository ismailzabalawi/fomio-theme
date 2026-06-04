import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  computeToolbarTriggerRect,
  computeToolbarViewportPosition,
} from "../javascripts/discourse/lib/fomio-selection-toolbar-geometry.js";

describe("fomio-selection-toolbar-extension", () => {
  it("anchors below the selection when the top toolbar would collide with the composer chrome", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 260, bottom: 282 },
      { left: 180, top: 260, bottom: 282 },
      220
    );

    assert.equal(rect.left, 150);
    assert.equal(rect.top, 300);
    assert.equal(rect.bottom, 300);
  });

  it("keeps an above-selection anchor when there is room", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 320, bottom: 342 },
      { left: 180, top: 320, bottom: 342 },
      60
    );

    assert.equal(rect.top, 302);
    assert.equal(rect.bottom, 360);
  });

  it("keeps the toolbar above when there is room below the composer topbar, even near the editor top", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 204, bottom: 225 },
      { left: 180, top: 204, bottom: 225 },
      59
    );

    assert.equal(rect.top, 186);
    assert.equal(rect.bottom, 243);
  });

  it("places the toolbar below when the trigger rect requests below-placement", () => {
    const pos = computeToolbarViewportPosition(
      { left: 150, top: 300, bottom: 300 },
      120,
      { width: 1280, height: 720 }
    );

    assert.equal(pos.top, 308);
    assert.equal(pos.left, 90);
  });

  it("places the toolbar above when there is room above the selection", () => {
    const pos = computeToolbarViewportPosition(
      { left: 150, top: 302, bottom: 360 },
      120,
      { width: 1280, height: 720 }
    );

    assert.equal(pos.top, 246);
    assert.equal(pos.left, 90);
  });
});
