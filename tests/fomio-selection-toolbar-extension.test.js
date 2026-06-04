import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  computeComposerToolbarSafeTop,
  getComposerSurfaceMode,
  computeToolbarTriggerRect,
  computeToolbarViewportPosition,
} from "../javascripts/discourse/lib/fomio-selection-toolbar-geometry.js";

describe("fomio-selection-toolbar-extension", () => {
  describe("getComposerSurfaceMode", () => {
    it("detects create mode from core composer classes", () => {
      assert.equal(
        getComposerSurfaceMode({
          replyControlClassName: "open composer-action-create-topic",
        }),
        "fullscreen"
      );
    });

    it("detects edit mode from core composer classes", () => {
      assert.equal(
        getComposerSurfaceMode({
          replyControlClassName: "open composer-action-edit",
        }),
        "fullscreen"
      );
    });

    it("treats the Fomio topbar as fullscreen mode even if class names drift", () => {
      assert.equal(
        getComposerSurfaceMode({
          hasFullscreenTopbar: true,
          replyControlClassName: "open composer-action-unknown",
        }),
        "fullscreen"
      );
    });

    it("detects reply mode explicitly", () => {
      assert.equal(
        getComposerSurfaceMode({
          replyControlClassName: "open composer-action-reply",
        }),
        "reply"
      );
    });

    it("falls back to default for other composer states", () => {
      assert.equal(
        getComposerSurfaceMode({
          replyControlClassName: "closed draft",
        }),
        "default"
      );
    });
  });

  describe("computeComposerToolbarSafeTop", () => {
    it("uses the fullscreen composer topbar when present", () => {
      assert.equal(
        computeComposerToolbarSafeTop({
          mode: "fullscreen",
          fullscreenTopbarBottom: 51,
        }),
        59
      );
    });

    it("falls back to viewport padding for reply mode", () => {
      assert.equal(computeComposerToolbarSafeTop({ mode: "reply" }), 8);
    });

    it("falls back to viewport padding for default mode", () => {
      assert.equal(computeComposerToolbarSafeTop({ mode: "default" }), 8);
      assert.equal(computeComposerToolbarSafeTop(), 8);
    });
  });

  it("anchors below the selection when the top toolbar would collide with the composer chrome", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 260, bottom: 282 },
      { left: 180, top: 260, bottom: 282 },
      computeComposerToolbarSafeTop({
        mode: "fullscreen",
        fullscreenTopbarBottom: 212,
      })
    );

    assert.equal(rect.left, 150);
    assert.equal(rect.top, 300);
    assert.equal(rect.bottom, 300);
  });

  it("keeps an above-selection anchor when there is room", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 320, bottom: 342 },
      { left: 180, top: 320, bottom: 342 },
      computeComposerToolbarSafeTop({
        mode: "fullscreen",
        fullscreenTopbarBottom: 52,
      })
    );

    assert.equal(rect.top, 302);
    assert.equal(rect.bottom, 360);
  });

  it("keeps the toolbar above when there is room below the composer topbar, even near the editor top", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 204, bottom: 225 },
      { left: 180, top: 204, bottom: 225 },
      computeComposerToolbarSafeTop({
        mode: "fullscreen",
        fullscreenTopbarBottom: 51,
      })
    );

    assert.equal(rect.top, 186);
    assert.equal(rect.bottom, 243);
  });

  it("uses the default above-first placement for reply composer geometry", () => {
    const rect = computeToolbarTriggerRect(
      { left: 120, top: 120, bottom: 141 },
      { left: 180, top: 120, bottom: 141 },
      computeComposerToolbarSafeTop({ mode: "reply" })
    );

    assert.equal(rect.top, 102);
    assert.equal(rect.bottom, 159);
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

  it("clamps the toolbar to the left viewport edge", () => {
    const pos = computeToolbarViewportPosition(
      { left: 20, top: 302, bottom: 360 },
      120,
      { width: 1280, height: 720 }
    );

    assert.equal(pos.left, 8);
  });

  it("clamps the toolbar to the right viewport edge", () => {
    const pos = computeToolbarViewportPosition(
      { left: 1270, top: 302, bottom: 360 },
      120,
      { width: 1280, height: 720 }
    );

    assert.equal(pos.left, 1152);
  });

  it("falls below the selection when above-placement would exit the viewport in reply mode", () => {
    const pos = computeToolbarViewportPosition(
      { left: 150, top: 20, bottom: 59 },
      120,
      { width: 1280, height: 720 }
    );

    assert.equal(pos.top, 67);
  });
});
