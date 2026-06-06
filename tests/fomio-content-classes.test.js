import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  avatarClassNames,
  avatarImageSize,
  cardClassNames,
  hasAvatarBadge,
  identityClassNames,
  listItemClassNames,
  listSectionHeaderClassNames,
  normalizeIdentitySize,
} from "../javascripts/discourse/lib/fomio-content-classes.js";

describe("fomio-content-classes", () => {
  it("normalizes avatar classes and image sizes", () => {
    const classes = avatarClassNames({
      size: "lg",
      variant: "sage",
      extraClass: "profile-avatar",
    });

    assert.match(classes, /\bfomio-avatar--lg\b/);
    assert.match(classes, /\bfomio-avatar--sage\b/);
    assert.match(classes, /\bprofile-avatar\b/);
    assert.equal(avatarImageSize({ size: "sm" }), "small");
    assert.equal(avatarImageSize({ size: "md" }), "large");
  });

  it("detects avatar badge state", () => {
    assert.equal(hasAvatarBadge({ online: true }), true);
    assert.equal(hasAvatarBadge({ badgeCount: 3 }), true);
    assert.equal(hasAvatarBadge({}), false);
  });

  it("normalizes card variants and disabled state", () => {
    const classes = cardClassNames({
      variant: "flat",
      interactive: true,
      disabled: true,
    });

    assert.match(classes, /\bfomio-card\b/);
    assert.match(classes, /\bfomio-card--flat\b/);
    assert.match(classes, /\bfomio-card--interactive\b/);
    assert.match(classes, /\bis-disabled\b/);
  });

  it("normalizes list item state aliases", () => {
    const classes = listItemClassNames({
      active: true,
      variant: "danger",
      disabled: true,
    });

    assert.match(classes, /\bfomio-list__item--active\b/);
    assert.match(classes, /\bfomio-list__item--danger\b/);
    assert.match(classes, /\bfomio-list__item--disabled\b/);
  });

  it("normalizes list section header classes", () => {
    assert.equal(
      listSectionHeaderClassNames({ extraClass: "menu-header" }),
      "fomio-list__section-header menu-header"
    );
  });

  it("normalizes identity size aliases", () => {
    assert.equal(normalizeIdentitySize({ large: true }), "lg");
    assert.equal(normalizeIdentitySize({ size: "md" }), "md");
    assert.match(identityClassNames({ size: "lg" }), /\bfomio-identity--lg\b/);
    assert.match(
      identityClassNames({ showAvatar: false }),
      /\bfomio-identity--avatarless\b/
    );
  });
});
