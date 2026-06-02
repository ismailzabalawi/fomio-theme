import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  buildHubEntityUrl,
  hubFilterSuffix,
  normalizeHubFilter,
} from "../javascripts/discourse/lib/fomio-hub-routes.js";

describe("fomio-hub-routes", () => {
  const hub = { id: 12, slug: "design" };
  const teret = { id: 34, slug: "critique" };

  it("keeps teret routes when changing sort filters", () => {
    assert.equal(
      buildHubEntityUrl({ hub, teret, filter: "top" }),
      "/c/design/critique/34/l/top"
    );
    assert.equal(
      buildHubEntityUrl({ hub, teret, filter: "new" }),
      "/c/design/critique/34/l/new"
    );
    assert.equal(
      buildHubEntityUrl({ hub, teret, filter: "latest" }),
      "/c/design/critique/34"
    );
  });

  it("keeps hub-root routes unchanged", () => {
    assert.equal(buildHubEntityUrl({ hub, filter: "latest" }), "/c/design/12");
    assert.equal(buildHubEntityUrl({ hub, filter: "top" }), "/c/design/12/l/top");
    assert.equal(buildHubEntityUrl({ hub, filter: "new" }), "/c/design/12/l/new");
  });

  it("normalizes the current filter from routed urls", () => {
    assert.equal(normalizeHubFilter("/c/design/12"), "latest");
    assert.equal(normalizeHubFilter("/c/design/critique/34/l/top"), "top");
    assert.equal(normalizeHubFilter("/c/design/critique/34/l/new?order=created"), "new");
  });

  it("returns the right suffix for each filter", () => {
    assert.equal(hubFilterSuffix("latest"), "");
    assert.equal(hubFilterSuffix("top"), "/l/top");
    assert.equal(hubFilterSuffix("new"), "/l/new");
  });
});
