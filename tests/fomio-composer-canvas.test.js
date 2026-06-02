import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  CANVAS_SELECTORS,
  shouldFocusCanvas,
} from "../javascripts/discourse/lib/fomio-composer-canvas.js";

const base = {
  isOpen: true,
  isFullPageMode: true,
  isCanvasSurface: true,
  isInsideEditable: false,
  isInteractive: false,
};

describe("fomio-composer-canvas", () => {
  it("focuses on a clean canvas click in create/edit", () => {
    assert.equal(shouldFocusCanvas(base), true);
  });

  it("does nothing when the composer is closed", () => {
    assert.equal(shouldFocusCanvas({ ...base, isOpen: false }), false);
  });

  it("does nothing in reply mode (not full-page)", () => {
    assert.equal(shouldFocusCanvas({ ...base, isFullPageMode: false }), false);
  });

  it("ignores clicks that are not on a canvas surface", () => {
    assert.equal(shouldFocusCanvas({ ...base, isCanvasSurface: false }), false);
  });

  it("never hijacks clicks inside the editable text", () => {
    assert.equal(shouldFocusCanvas({ ...base, isInsideEditable: true }), false);
  });

  it("never hijacks clicks on controls or fields", () => {
    assert.equal(shouldFocusCanvas({ ...base, isInteractive: true }), false);
  });

  it("returns false for empty input (defensive)", () => {
    assert.equal(shouldFocusCanvas(), false);
    assert.equal(shouldFocusCanvas({}), false);
  });

  it("exposes the canvas surface selectors", () => {
    assert.ok(CANVAS_SELECTORS.includes(".reply-area"));
    assert.ok(CANVAS_SELECTORS.includes(".d-editor-textarea-wrapper"));
  });
});
