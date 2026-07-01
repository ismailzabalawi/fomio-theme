import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  actionKeyFromActionType,
  actionKeyFromItem,
  bindBytesTypeLabelToMeta,
  bindTimelineTypeLabelToMetadata,
  fallbackLabelForActionKey,
  iconForActionKey,
} from "../javascripts/discourse/lib/fomio-activity-timeline.js";

describe("fomio-activity-timeline", () => {
  it("maps action_type to action keys", () => {
    assert.equal(actionKeyFromActionType(4), "created_byte");
    assert.equal(actionKeyFromActionType(5), "replied");
    assert.equal(actionKeyFromActionType(1), "liked");
    assert.equal(actionKeyFromActionType(99), null);
    assert.equal(actionKeyFromActionType(null), null);
  });

  it("maps stream items to action keys", () => {
    assert.equal(actionKeyFromItem({ action_type: 4 }), "created_byte");
    assert.equal(actionKeyFromItem({ get: (k) => (k === "action_type" ? 5 : null) }), "replied");
    assert.equal(actionKeyFromItem({}), null);
  });

  it("returns phosphor icon names per action key", () => {
    assert.equal(iconForActionKey("created_byte"), "fomio-ph-note-pencil");
    assert.equal(iconForActionKey("replied"), "fomio-ph-arrow-bend-up-left");
    assert.equal(iconForActionKey("liked"), "fomio-ph-heart");
    assert.equal(iconForActionKey("unknown"), "fomio-ph-rows");
  });

  it("returns plain fallback labels for activity rows", () => {
    assert.equal(fallbackLabelForActionKey("created_byte"), "Created a Byte");
    assert.equal(fallbackLabelForActionKey("replied"), "Replied");
    assert.equal(fallbackLabelForActionKey("liked"), "Liked");
    assert.equal(fallbackLabelForActionKey("unknown"), null);
  });

  it("no-ops when prefix or metadata is missing", () => {
    assert.equal(bindTimelineTypeLabelToMetadata(null), undefined);
    assert.equal(bindTimelineTypeLabelToMetadata(undefined), undefined);
    assert.equal(bindBytesTypeLabelToMeta(null), undefined);
    assert.equal(bindBytesTypeLabelToMeta(undefined), undefined);
  });
});
