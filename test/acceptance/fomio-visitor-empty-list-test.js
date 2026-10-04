// fomio-visitor-empty-list.gjs — core's empty-list state for visitors
// (4.5). Run on a development Discourse (docs/04).
import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import topicFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

const EMPTY = ".empty-state__container.--empty-topic-filter";
const CTA = `${EMPTY} .empty-state__cta .btn`;
const LINKS = `${EMPTY} .fomio-visitor-empty-list__link`;

function emptyList() {
  return { topic_list: { can_create_topic: false, topics: [] } };
}

acceptance("Fomio | Visitor empty list", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/hot.json", () => helper.response(emptyList()));
    server.get("/c/bug/1/l/latest.json", () => helper.response(emptyList()));
    server.get("/latest.json", () =>
      helper.response(cloneJSON(topicFixtures["/latest.json"]))
    );
  });

  test("an empty category offers Latest, then Categories and Hot", async function (assert) {
    await visit("/c/bug/1/l/latest");
    assert.dom(EMPTY).exists("core's empty state, signed out");
    assert
      .dom(`${EMPTY} .empty-state__title`)
      .hasText(i18n("topics.none.education.generic"));
    assert.dom(CTA).hasText(i18n("topic.browse_latest_topics"));
    assert
      .dom(LINKS)
      .exists({ count: 2 })
      .hasAttribute("href", "/categories", "Categories first");

    await click(CTA);
    assert.strictEqual(currentURL(), "/latest");
    assert.dom(EMPTY).doesNotExist("Latest has topics");
  });

  test("an empty site-wide Hot does not link to itself", async function (assert) {
    await visit("/hot");
    assert.dom(CTA).hasText(i18n("topic.browse_latest_topics"));
    assert.dom(LINKS).exists({ count: 1 }).hasAttribute("href", "/categories");
  });

  test("a list with topics shows nothing", async function (assert) {
    await visit("/latest");
    assert.dom(EMPTY).doesNotExist();
  });
});

acceptance("Fomio | Visitor empty list, empty site", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/latest.json", () => helper.response(emptyList()));
  });

  test("an empty site-wide Latest points to Categories only", async function (assert) {
    await visit("/latest");
    assert.dom(CTA).hasText(i18n("filters.categories.title"));
    assert.dom(`${EMPTY} .empty-state__tip`).doesNotExist();
  });
});

acceptance("Fomio | Visitor empty list, signed in", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/c/bug/1/l/latest.json", () =>
      helper.response({ topic_list: { can_create_topic: true, topics: [] } })
    );
  });

  test("core's member state only, no second copy", async function (assert) {
    await visit("/c/bug/1/l/latest");
    assert.dom(EMPTY).exists({ count: 1 });
    assert.dom(LINKS).doesNotExist();
  });
});
