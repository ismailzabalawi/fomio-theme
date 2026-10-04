import { click, settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Fomio | Composer audience", function (needs) {
  needs.user();
  needs.settings({ enable_composer_redesign: true });
  needs.site({
    categories: [
      { id: 42, name: "Open category", read_restricted: false },
      { id: 43, name: "Restricted category", read_restricted: true },
      { id: 44, name: "Unresolved category" },
    ],
  });

  test("visibility stays in the category control and clears when access changes", async function (assert) {
    await visit("/latest");
    await click("#create-topic");
    const model = this.container.lookup("service:composer").model;
    model.set("categoryId", 42);
    await settled();
    assert.dom(".fomio-composer-audience").doesNotExist();
    assert.dom("#reply-control .category-chooser .restricted").doesNotExist();

    model.set("categoryId", 43);
    await settled();
    assert.dom("#reply-control .category-chooser .restricted").exists();
    assert.dom("#reply-control .category-chooser .select-kit-header")
      .hasAttribute("title", i18n(themePrefix("composer.restricted_category")))
      .hasAttribute("aria-description", i18n(themePrefix("composer.restricted_category")));

    model.set("categoryId", 42);
    await settled();
    assert.dom("#reply-control .category-chooser .select-kit-header")
      .doesNotHaveAttribute("aria-description");

    model.set("categoryId", 44);
    await settled();
    assert.dom(".fomio-composer-audience").doesNotExist();
    assert.dom("#reply-control .create").exists({ count: 1 });
  });
});
