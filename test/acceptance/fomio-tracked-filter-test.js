// fomio-tracked-filter.js — the Tracked on/off filter (2C) and its empty
// state (2D). Run at /theme-qunit?id=36 (docs/04).
import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import topicFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

const PILL = "#navigation-bar li.fomio-tracked > a";
const EMPTY = ".empty-state__container.--empty-topic-filter";

acceptance("Fomio | Tracked filter", function (needs) {
  needs.user();

  // A member who tracks nothing: `f=tracked` returns an empty list, as the
  // server does (TopicQuery.tracked_filter).
  needs.pretender((server, helper) => {
    server.get("/latest.json", (request) => {
      const json = cloneJSON(topicFixtures["/latest.json"]);
      if (request.queryParams.f === "tracked") {
        json.topic_list.topics = [];
        delete json.topic_list.more_topics_url;
      }
      return helper.response(json);
    });
  });

  test("toggles f=tracked over the current tab", async function (assert) {
    await visit("/latest");
    assert.dom(PILL).hasText(i18n("user.tracked_categories"));
    assert.dom("#navigation-bar li.fomio-tracked").doesNotHaveClass("--on");

    await click(PILL);
    assert.strictEqual(currentURL(), "/latest?f=tracked", "on");
    assert.dom("#navigation-bar li.fomio-tracked").hasClass("--on");
    assert.dom("#navigation-bar li.latest > a").hasClass("active");

    await click(PILL);
    assert.strictEqual(currentURL(), "/latest", "off");
    assert.dom("#navigation-bar li.fomio-tracked").doesNotHaveClass("--on");
  });

  test("the empty state's button leaves the filter", async function (assert) {
    await visit("/latest?f=tracked");
    assert.dom(EMPTY).exists("core's empty state shows");

    await click(`${EMPTY} .empty-state__cta .btn`);
    assert.strictEqual(currentURL(), "/latest", "Latest, unfiltered");
    assert.dom(EMPTY).doesNotExist();
    assert.dom("#navigation-bar li.fomio-tracked").doesNotHaveClass("--on");
  });

  test("not on the categories page", async function (assert) {
    await visit("/categories");
    assert.dom("#navigation-bar li.fomio-tracked").doesNotExist();
  });
});

acceptance("Fomio | Tracked filter, signed out", function () {
  test("not shown", async function (assert) {
    await visit("/latest");
    assert.dom("#navigation-bar li.fomio-tracked").doesNotExist();
  });
});

// Unified New (on for meta.fomio.app since 2026-09; docs/02): New carries
// core's All · Topics · Replies subtabs as `?subset=`. Tracked only touches
// `f`, so the chosen subset must survive turning it on and off.
function params() {
  return new URL(currentURL(), window.location.origin).searchParams;
}

acceptance("Fomio | Tracked filter, Unified New", function (needs) {
  needs.user({ unified_new_enabled: true });

  needs.pretender((server, helper) => {
    server.get("/new.json", () =>
      helper.response({ topic_list: { can_create_topic: true, topics: [] } })
    );
  });

  test("keeps the New subset while toggling Tracked", async function (assert) {
    await visit("/new?subset=replies");
    assert.dom(".topics-replies-toggle.--replies").hasClass("active");

    await click(PILL);
    assert.strictEqual(params().get("f"), "tracked", "on");
    assert.strictEqual(params().get("subset"), "replies", "subset kept");
    assert.dom(".topics-replies-toggle.--replies").hasClass("active");

    await click(PILL);
    assert.strictEqual(params().get("f"), null, "off");
    assert.strictEqual(params().get("subset"), "replies", "subset kept");
    assert.dom(".topics-replies-toggle.--replies").hasClass("active");
  });

  test("switching subset keeps Tracked on", async function (assert) {
    await visit("/new?f=tracked");
    await click(".topics-replies-toggle.--topics");
    assert.strictEqual(params().get("f"), "tracked");
    assert.strictEqual(params().get("subset"), "topics");
    assert.dom("#navigation-bar li.fomio-tracked").hasClass("--on");
  });
});

// Phones (2E, fomio-mobile-tabs.js): core's pills stay inline, so Tracked
// and the New subtabs are both on screen, not behind the dropdown.
acceptance("Fomio | Tracked filter, Unified New, mobile", function (needs) {
  needs.user({ unified_new_enabled: true });
  needs.mobileView();

  needs.pretender((server, helper) => {
    server.get("/new.json", () =>
      helper.response({ topic_list: { can_create_topic: true, topics: [] } })
    );
  });

  test("inline tabs with subtabs, subset kept", async function (assert) {
    await visit("/new?subset=topics");
    assert.dom(".list-control-toggle-link-trigger").doesNotExist();
    assert.dom(PILL).exists();
    assert.dom(".topics-replies-toggle.--topics").hasClass("active");

    await click(PILL);
    assert.strictEqual(params().get("f"), "tracked");
    assert.strictEqual(params().get("subset"), "topics");
  });
});
