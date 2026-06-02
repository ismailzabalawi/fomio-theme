import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  buildFomioHubCatalog,
  FOMIO_TOP_LEVEL_HUB_LIMIT,
} from "../javascripts/discourse/lib/fomio-hub-catalog.js";

describe("fomio-hub-catalog", () => {
  it("excludes uncategorized and dedupes repeated category sources", () => {
    const repeatedHub = { id: 1, slug: "alpha", name: "Alpha", color: "111111" };
    const overflowHub = { id: 4, slug: "beta", name: "Beta", color: "333333" };
    const catalog = buildFomioHubCatalog([
      [
        repeatedHub,
        { id: 2, slug: "uncategorized", name: "Uncategorized", color: "222222" },
        { id: 3, slug: "alpha-chat", name: "Alpha Chat", parent_category_id: 1 },
        overflowHub,
      ],
      {
        toArray() {
          return [repeatedHub];
        },
      },
    ]);

    assert.deepEqual(
      catalog.topLevelHubs.map((hub) => hub.slug),
      ["alpha", "beta"]
    );
    assert.deepEqual(
      catalog.allTopLevelHubs.map((hub) => hub.slug),
      ["alpha", "beta"]
    );
    assert.equal(catalog.categories.length, 4);
    assert.equal(catalog.hasMoreHubs, false);
  });

  it("applies a consistent top-level hub cap", () => {
    const categories = Array.from(
      { length: FOMIO_TOP_LEVEL_HUB_LIMIT + 2 },
      (_, index) => ({
        id: index + 1,
        slug: `hub-${index + 1}`,
        name: `Hub ${index + 1}`,
      })
    );

    const catalog = buildFomioHubCatalog([categories]);

    assert.equal(catalog.topLevelHubs.length, FOMIO_TOP_LEVEL_HUB_LIMIT);
    assert.equal(catalog.allTopLevelHubs.length, categories.length);
    assert.equal(catalog.hasMoreHubs, true);
    assert.deepEqual(
      catalog.topLevelHubs.map((hub) => hub.slug),
      categories
        .slice(0, FOMIO_TOP_LEVEL_HUB_LIMIT)
        .map((hub) => hub.slug)
    );
    assert.deepEqual(
      catalog.allTopLevelHubs.map((hub) => hub.slug),
      categories.map((hub) => hub.slug)
    );
  });
});
