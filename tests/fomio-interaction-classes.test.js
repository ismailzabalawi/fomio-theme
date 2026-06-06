import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  dropdownPanelClassNames,
  ephemeralSheetBackdropClassNames,
  ephemeralSheetClassNames,
  normalizedSegmentedOptions,
  notificationsMenuClassNames,
  normalizeSheetVariant,
  searchSheetBackdropClass,
  searchSheetClassNames,
  segmentedButtonClassNames,
  segmentedWrapperClassNames,
} from "../javascripts/discourse/lib/fomio-interaction-classes.js";

describe("fomio-interaction-classes", () => {
  it("normalizes segmented options from value aliases", () => {
    const options = normalizedSegmentedOptions({
      selected: "list",
      options: [
        { id: "grid", label: "Grid" },
        { value: "list", label: "List", disabled: true },
      ],
    });

    assert.equal(options[0].isActive, false);
    assert.equal(options[1].isActive, true);
    assert.equal(options[1].isDisabled, true);
  });

  it("builds segmented wrapper and button classes", () => {
    assert.match(
      segmentedWrapperClassNames({ variant: "compact", wrapperClass: "picker" }),
      /\bfomio-seg--compact\b/
    );

    const classes = segmentedButtonClassNames(
      { isActive: true, isDisabled: true },
      { size: "sm", buttonClass: "hub-btn" }
    );

    assert.match(classes, /\bactive\b/);
    assert.match(classes, /\bis-active\b/);
    assert.match(classes, /\bis-disabled\b/);
    assert.match(classes, /\bfomio-seg-btn--sm\b/);
    assert.match(classes, /\bhub-btn\b/);
  });

  it("normalizes search sheet classes and backdrop behavior", () => {
    assert.equal(normalizeSheetVariant({ mode: "mobile" }), "mobile");
    assert.equal(searchSheetBackdropClass({ variant: "desktop" }), "fomio-search-sheet__backdrop");
    assert.equal(searchSheetBackdropClass({ variant: "mobile" }), null);
    assert.equal(
      searchSheetClassNames({ source: "desktop", extraClass: "palette" }),
      "fomio-search-sheet fomio-search-sheet--desktop palette"
    );
  });

  it("builds dropdown panel classes with feature-level overrides", () => {
    assert.equal(
      dropdownPanelClassNames({ panelClass: "composer-panel" }),
      "fomio-dropdown__panel composer-panel"
    );
  });

  it("normalizes ephemeral sheet classes", () => {
    assert.equal(
      ephemeralSheetClassNames({ variant: "drawer", side: "right", panelClass: "sheet" }),
      "fomio-ephemeral-sheet fomio-ephemeral-sheet--drawer fomio-ephemeral-sheet--right sheet"
    );
    assert.equal(
      ephemeralSheetBackdropClassNames({ variant: "drawer", backdropClass: "dim" }),
      "fomio-ephemeral-sheet-backdrop fomio-ephemeral-sheet-backdrop--drawer dim"
    );
  });

  it("normalizes notifications menu classes", () => {
    assert.equal(
      notificationsMenuClassNames("mobile", "overlay"),
      "fomio-notifications-menu fomio-notifications-menu--mobile overlay"
    );
    assert.equal(
      notificationsMenuClassNames("other"),
      "fomio-notifications-menu fomio-notifications-menu--desktop"
    );
  });
});
