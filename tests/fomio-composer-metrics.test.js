import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  computeChecks,
  countChars,
  countWords,
  extractOutline,
  findActiveOutlinePos,
  MIN_CHARS,
  progressPct,
  readTimeMinutes,
  RECOMMENDED_MAX,
} from "../javascripts/discourse/lib/fomio-composer-metrics.js";

describe("fomio-composer-metrics", () => {
  describe("countWords", () => {
    it("returns 0 for empty / null / whitespace", () => {
      assert.equal(countWords(""), 0);
      assert.equal(countWords(null), 0);
      assert.equal(countWords(undefined), 0);
      assert.equal(countWords("   \n\t  "), 0);
    });

    it("counts whitespace-delimited words and collapses runs", () => {
      assert.equal(countWords("hello world"), 2);
      assert.equal(countWords("  the   quiet  rituals \n of reading "), 5);
      assert.equal(countWords("one"), 1);
    });
  });

  describe("countChars", () => {
    it("returns total length, 0 for null", () => {
      assert.equal(countChars(""), 0);
      assert.equal(countChars(null), 0);
      assert.equal(countChars("abc"), 3);
      assert.equal(countChars("a b"), 3);
    });
  });

  describe("readTimeMinutes", () => {
    it("is 0 for no words", () => {
      assert.equal(readTimeMinutes(0), 0);
      assert.equal(readTimeMinutes(null), 0);
    });

    it("is at least 1 minute for any words and rounds up", () => {
      assert.equal(readTimeMinutes(1), 1);
      assert.equal(readTimeMinutes(200), 1);
      assert.equal(readTimeMinutes(201), 2);
      assert.equal(readTimeMinutes(312), 2);
      assert.equal(readTimeMinutes(600), 3);
    });
  });

  describe("extractOutline", () => {
    it("returns [] for non-arrays", () => {
      assert.deepEqual(extractOutline(null), []);
      assert.deepEqual(extractOutline(undefined), []);
      assert.deepEqual(extractOutline("nope"), []);
    });

    it("drops blank headings and trims text", () => {
      assert.deepEqual(
        extractOutline([
          { level: 2, text: "  Three small rituals  ", pos: 4 },
          { level: 3, text: "" },
          { level: 3, text: "   " },
          { level: 3, text: "A notebook", pos: 28 },
        ]),
        [
          { level: 2, text: "Three small rituals", pos: 4 },
          { level: 3, text: "A notebook", pos: 28 },
        ]
      );
    });

    it("defaults invalid levels to 1", () => {
      assert.deepEqual(extractOutline([{ level: 0, text: "x" }]), [
        { level: 1, text: "x", pos: null },
      ]);
      assert.deepEqual(extractOutline([{ text: "y" }]), [
        { level: 1, text: "y", pos: null },
      ]);
    });
  });

  describe("findActiveOutlinePos", () => {
    const outline = [
      { level: 2, text: "Start", pos: 2 },
      { level: 2, text: "Middle", pos: 18 },
      { level: 3, text: "Detail", pos: 41 },
    ];

    it("returns null for invalid inputs", () => {
      assert.equal(findActiveOutlinePos(null, 10), null);
      assert.equal(findActiveOutlinePos(outline, NaN), null);
    });

    it("returns the nearest heading at/before cursor", () => {
      assert.equal(findActiveOutlinePos(outline, 2), 2);
      assert.equal(findActiveOutlinePos(outline, 12), 2);
      assert.equal(findActiveOutlinePos(outline, 18), 18);
      assert.equal(findActiveOutlinePos(outline, 999), 41);
    });

    it("returns null when cursor is before first heading", () => {
      assert.equal(findActiveOutlinePos(outline, 1), null);
    });
  });

  describe("computeChecks", () => {
    it("handles empty input", () => {
      assert.deepEqual(computeChecks(), {
        titleSet: false,
        teretChosen: false,
        minLength: false,
      });
      assert.deepEqual(computeChecks({}), {
        titleSet: false,
        teretChosen: false,
        minLength: false,
      });
    });

    it("titleSet ignores whitespace-only titles", () => {
      assert.equal(computeChecks({ title: "   " }).titleSet, false);
      assert.equal(computeChecks({ title: "Hi" }).titleSet, true);
    });

    it("teretChosen is true for category id 0 (a valid id)", () => {
      assert.equal(computeChecks({ categoryId: 0 }).teretChosen, true);
      assert.equal(computeChecks({ categoryId: 5 }).teretChosen, true);
      assert.equal(computeChecks({ categoryId: null }).teretChosen, false);
      assert.equal(computeChecks({ categoryId: undefined }).teretChosen, false);
    });

    it("minLength flips at the 280-char boundary", () => {
      assert.equal(computeChecks({ chars: MIN_CHARS - 1 }).minLength, false);
      assert.equal(computeChecks({ chars: MIN_CHARS }).minLength, true);
      assert.equal(computeChecks({ chars: MIN_CHARS + 1 }).minLength, true);
    });
  });

  describe("progressPct", () => {
    it("is 0 for no words and clamps to 100 at/above max", () => {
      assert.equal(progressPct(0), 0);
      assert.equal(progressPct(null), 0);
      assert.equal(progressPct(RECOMMENDED_MAX), 100);
      assert.equal(progressPct(RECOMMENDED_MAX * 2), 100);
    });

    it("is monotonic mid-range", () => {
      assert.equal(progressPct(600), 50);
      assert.equal(progressPct(300), 25);
      assert.ok(progressPct(700) > progressPct(600));
    });
  });
});
