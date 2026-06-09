import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  DESKTOP_MASTER_PANE_OPEN_CLASS,
  isTouchViewportWidth,
  reconcileFomioSurfaceState,
  resolveFomioSurfaceMode,
  shortestViewportSide,
  TOUCH_SHELL_OPEN_CLASS,
} from "../javascripts/discourse/lib/fomio-surface-mode.js";

describe("fomio-surface-mode", () => {
  it("treats widths below 768px as touch", () => {
    assert.equal(isTouchViewportWidth(767), true);
    assert.equal(isTouchViewportWidth(768), false);
    assert.equal(
      resolveFomioSurfaceMode({ width: 767, height: 1024, coarsePointer: false, noHover: false }),
      "touch"
    );
  });

  it("maps the documented desktop surface ranges", () => {
    assert.equal(
      resolveFomioSurfaceMode({ width: 768, height: 1024, coarsePointer: false, noHover: false }),
      "rail"
    );
    assert.equal(
      resolveFomioSurfaceMode({ width: 1024, height: 900, coarsePointer: false, noHover: false }),
      "compact-desktop"
    );
    assert.equal(
      resolveFomioSurfaceMode({ width: 1280, height: 900, coarsePointer: false, noHover: false }),
      "expanded"
    );
  });

  it("keeps phone-class coarse-touch devices on touch in landscape", () => {
    assert.equal(shortestViewportSide(812, 375), 375);
    assert.equal(
      resolveFomioSurfaceMode({ width: 812, height: 375, coarsePointer: true, noHover: true }),
      "touch"
    );
  });

  it("keeps tablet-class coarse-touch devices on rail and above", () => {
    assert.equal(
      resolveFomioSurfaceMode({ width: 768, height: 1024, coarsePointer: true, noHover: true }),
      "rail"
    );
    assert.equal(
      resolveFomioSurfaceMode({ width: 1180, height: 820, coarsePointer: true, noHover: true }),
      "compact-desktop"
    );
  });

  it("clears transient shell state when crossing between touch and non-touch modes", () => {
    const classList = new Set([TOUCH_SHELL_OPEN_CLASS, DESKTOP_MASTER_PANE_OPEN_CLASS]);
    const fakeClassList = {
      remove(...classNames) {
        classNames.forEach((className) => classList.delete(className));
      },
    };

    reconcileFomioSurfaceState(fakeClassList, "touch", "rail");
    assert.equal(classList.has(TOUCH_SHELL_OPEN_CLASS), false);
    assert.equal(classList.has(DESKTOP_MASTER_PANE_OPEN_CLASS), false);
  });

  it("preserves transient desktop state when only resizing within non-touch modes", () => {
    const classList = new Set([DESKTOP_MASTER_PANE_OPEN_CLASS]);
    const fakeClassList = {
      remove(...classNames) {
        classNames.forEach((className) => classList.delete(className));
      },
    };

    reconcileFomioSurfaceState(fakeClassList, "rail", "expanded");
    assert.equal(classList.has(DESKTOP_MASTER_PANE_OPEN_CLASS), true);
  });
});
