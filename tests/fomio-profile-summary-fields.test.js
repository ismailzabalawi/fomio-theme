import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  formatStatValue,
  profileSummaryStats,
  profileTopTerets,
} from "../javascripts/discourse/lib/fomio-profile-summary-fields.js";

describe("fomio-profile-summary-fields", () => {
  describe("formatStatValue", () => {
    it("renders small counts verbatim", () => {
      assert.equal(formatStatValue(0), "0");
      assert.equal(formatStatValue(999), "999");
    });

    it("compacts thousands to a k suffix and trims trailing .0", () => {
      assert.equal(formatStatValue(1000), "1k");
      assert.equal(formatStatValue(1200), "1.2k");
      assert.equal(formatStatValue(12345), "12.3k");
    });

    it("treats non-finite values as zero", () => {
      assert.equal(formatStatValue(undefined), "0");
      assert.equal(formatStatValue(null), "0");
      assert.equal(formatStatValue(NaN), "0");
    });
  });

  describe("profileSummaryStats", () => {
    it("maps serializer fields to Fomio stat descriptors in order", () => {
      const stats = profileSummaryStats({
        topic_count: 1200,
        post_count: 48,
        likes_received: 340,
        likes_given: 12,
      });

      assert.deepEqual(
        stats.map((s) => s.key),
        ["bytes", "replies", "received", "given"]
      );
      assert.deepEqual(
        stats.map((s) => s.count),
        [1200, 48, 340, 12]
      );
      assert.deepEqual(
        stats.map((s) => s.formatted),
        ["1.2k", "48", "340", "12"]
      );
    });

    it("zero-fills missing fields so the row stays stable", () => {
      const stats = profileSummaryStats({});
      assert.equal(stats.length, 4);
      assert.ok(stats.every((s) => s.count === 0 && s.formatted === "0"));
    });

    it("tolerates a null/undefined model", () => {
      assert.equal(profileSummaryStats(null).length, 4);
      assert.equal(profileSummaryStats(undefined).length, 4);
    });

    it("flags bytes/replies as pluralizable and likes as not", () => {
      const byKey = Object.fromEntries(
        profileSummaryStats({}).map((s) => [s.key, s.pluralize])
      );
      assert.equal(byKey.bytes, true);
      assert.equal(byKey.replies, true);
      assert.equal(byKey.received, false);
      assert.equal(byKey.given, false);
    });
  });

  describe("profileTopTerets", () => {
    const model = {
      top_categories: [
        { id: 1, name: "Essays", color: "C44536", topic_count: 10, post_count: 8 },
        { id: 2, name: "Craft", color: "6B6B72", topic_count: 4, post_count: 5 },
        { id: 3, name: "Letters", color: null, topic_count: 1, post_count: 0 },
      ],
    };

    it("sums topics + replies into a total count", () => {
      const rows = profileTopTerets(model);
      assert.deepEqual(
        rows.map((r) => r.count),
        [18, 9, 1]
      );
    });

    it("scales pct to the busiest teret (0–100)", () => {
      const rows = profileTopTerets(model);
      assert.equal(rows[0].pct, 100);
      assert.equal(rows[1].pct, 50);
      assert.equal(rows[2].pct, 6);
    });

    it("prefixes a hex color and tolerates a missing one", () => {
      const rows = profileTopTerets(model);
      assert.equal(rows[0].color, "#C44536");
      assert.equal(rows[2].color, null);
    });

    it("honours the limit and tolerates a missing list", () => {
      assert.equal(profileTopTerets(model, 2).length, 2);
      assert.deepEqual(profileTopTerets({}), []);
      assert.deepEqual(profileTopTerets({ top_categories: null }), []);
      assert.deepEqual(profileTopTerets(null), []);
    });

    it("yields pct 0 for all rows when every count is zero", () => {
      const rows = profileTopTerets({
        top_categories: [{ id: 1, name: "Quiet", topic_count: 0, post_count: 0 }],
      });
      assert.equal(rows[0].pct, 0);
    });
  });
});
