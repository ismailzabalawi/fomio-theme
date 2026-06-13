import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  bannerClassNames,
  dropdownPanelClassNames,
  ephemeralSheetBackdropClassNames,
  ephemeralSheetClassNames,
  iconPillClassNames,
  noticeClassNames,
  normalizedSegmentedOptions,
  normalizeMessageTone,
  notificationsMenuClassNames,
  normalizeSheetVariant,
  popoverClassNames,
  searchSheetBackdropClass,
  searchSheetClassNames,
  segmentedButtonClassNames,
  segmentedWrapperClassNames,
  spinnerClassNames,
  switchClassNames,
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

  it("defaults message tone to info and reads aliases", () => {
    assert.equal(normalizeMessageTone(), "info");
    assert.equal(normalizeMessageTone({ tone: "danger" }), "danger");
    assert.equal(normalizeMessageTone({ variant: "success" }), "success");
  });

  it("builds notice classes with tone, dismissible, and extras", () => {
    assert.equal(noticeClassNames(), "fomio-notice fomio-notice--info");
    assert.equal(
      noticeClassNames({ tone: "warning", dismissible: true, extraClass: "stack" }),
      "fomio-notice fomio-notice--warning fomio-notice--dismissible stack"
    );
  });

  it("builds banner classes with tone and dismissible", () => {
    assert.equal(bannerClassNames(), "fomio-banner fomio-banner--info");
    assert.equal(
      bannerClassNames({ variant: "danger", dismissible: true }),
      "fomio-banner fomio-banner--danger fomio-banner--dismissible"
    );
  });

  it("builds popover classes with alignment and extras", () => {
    assert.equal(popoverClassNames(), "fomio-popover");
    assert.equal(
      popoverClassNames({ align: "end", panelClass: "anchored" }),
      "fomio-popover fomio-popover--align-end anchored"
    );
  });

  it("builds switch classes with checked and disabled state", () => {
    assert.equal(switchClassNames(), "fomio-switch");
    assert.equal(switchClassNames({ checked: true }), "fomio-switch fomio-switch--on");
    assert.equal(
      switchClassNames({ checked: true, disabled: true }),
      "fomio-switch fomio-switch--on fomio-switch--disabled"
    );
  });

  it("builds icon-pill classes with tone and size", () => {
    assert.equal(iconPillClassNames(), "fomio-icon-pill");
    assert.equal(
      iconPillClassNames({ tone: "danger" }),
      "fomio-icon-pill fomio-icon-pill--danger"
    );
    assert.equal(
      iconPillClassNames({ variant: "success", size: "lg" }),
      "fomio-icon-pill fomio-icon-pill--success fomio-icon-pill--lg"
    );
  });

  it("builds spinner classes with tone and size", () => {
    assert.equal(spinnerClassNames(), "fomio-spinner");
    assert.equal(
      spinnerClassNames({ tone: "accent", size: "sm" }),
      "fomio-spinner fomio-spinner--sm fomio-spinner--accent"
    );
    assert.equal(
      spinnerClassNames({ variant: "danger", size: "lg" }),
      "fomio-spinner fomio-spinner--lg fomio-spinner--danger"
    );
  });
});
