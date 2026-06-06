import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  buttonClassNames,
  inputClassNames,
  isControlDisabled,
  isControlLoading,
  wrapClassNames,
} from "../javascripts/discourse/lib/fomio-control-classes.js";

describe("fomio-control-classes", () => {
  it("normalizes button variants and loading aliases", () => {
    const classes = buttonClassNames({
      variant: "destructive",
      size: "sm",
      loading: true,
      iconOnly: true,
    });

    assert.match(classes, /\bfomio-btn-danger\b/);
    assert.match(classes, /\bfomio-btn--sm\b/);
    assert.match(classes, /\bfomio-btn--icon\b/);
    assert.match(classes, /\bis-loading\b/);
    assert.match(classes, /\bfomio-btn--loading\b/);
  });

  it("derives disabled from loading state", () => {
    assert.equal(isControlLoading({ isLoading: true }), true);
    assert.equal(isControlDisabled({ loading: true }), true);
    assert.equal(isControlDisabled({ disabled: false, loading: false }), false);
  });

  it("adds input icon and state classes", () => {
    const classes = inputClassNames({
      leadingIcon: "magnifying-glass",
      trailingIcon: "search",
      error: "Required",
      size: "lg",
      variant: "search",
    });

    assert.match(classes, /\bhas-prefix\b/);
    assert.match(classes, /\bhas-suffix\b/);
    assert.match(classes, /\bis-error\b/);
    assert.match(classes, /\bfomio-input--lg\b/);
    assert.match(classes, /\bfomio-input--search\b/);
  });

  it("adds wrapper hooks for variant and loading", () => {
    const classes = wrapClassNames("fomio-search-wrap", {
      variant: "desktop",
      loading: true,
      wrapperClass: "custom-shell",
    });

    assert.match(classes, /\bfomio-search-wrap--desktop\b/);
    assert.match(classes, /\bis-loading\b/);
    assert.match(classes, /\bcustom-shell\b/);
  });
});
