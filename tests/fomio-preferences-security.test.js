import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  isPreferencesProfilePath,
  isPreferencesSecurityPath,
  resolveSecurityActionVariant,
} from "../javascripts/discourse/lib/fomio-preferences-security.js";

describe("fomio-preferences-security", () => {
  it("matches both my/preferences and user preferences security routes", () => {
    assert.equal(isPreferencesSecurityPath("/my/preferences/security"), true);
    assert.equal(isPreferencesSecurityPath("/u/soma/preferences/security"), true);
    assert.equal(isPreferencesSecurityPath("/u/soma/preferences/account"), false);
    assert.equal(isPreferencesSecurityPath("/latest"), false);
  });

  it("matches both my/preferences and user preferences profile routes", () => {
    assert.equal(isPreferencesProfilePath("/my/preferences/profile"), true);
    assert.equal(isPreferencesProfilePath("/u/soma/preferences/profile"), true);
    assert.equal(isPreferencesProfilePath("/u/soma/preferences/security"), false);
  });

  it("classifies revoke and undo actions against translated labels", () => {
    assert.equal(
      resolveSecurityActionVariant("Revoke Access", {
        revokeLabel: "Revoke Access",
        undoLabel: "Undo Revoke Access",
      }),
      "danger"
    );

    assert.equal(
      resolveSecurityActionVariant("  Undo   Revoke Access ", {
        revokeLabel: "Revoke Access",
        undoLabel: "Undo Revoke Access",
      }),
      "secondary"
    );

    assert.equal(
      resolveSecurityActionVariant("Manage Two-Factor Authentication", {
        revokeLabel: "Revoke Access",
        undoLabel: "Undo Revoke Access",
      }),
      null
    );
  });
});
