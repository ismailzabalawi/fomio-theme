import {
  click,
  fillIn,
  settled,
  triggerEvent,
  visit,
} from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

// Real native editors and native command handlers. Requests are intercepted
// by Discourse's test harness; no live draft or post is created.
for (const mobile of [false, true]) {
  for (const redesign of [false, true]) {
    acceptance(
      `Fomio | Composer formatting mobile=${mobile} redesign=${redesign}`,
      function (needs) {
        needs.user();
        needs.settings({
          enable_composer_redesign: redesign,
          allow_uncategorized_topics: true,
        });
        if (mobile) {
          needs.mobileView();
        }

        test("native selection, rich conversion and minimize preserve the document", async function (assert) {
          await visit("/latest");
          await click("#create-topic");
          await fillIn(".d-editor-input", "A quieter morning");
          const input = document.querySelector("textarea.d-editor-input");
          input.focus();
          input.setSelectionRange(2, 9);
          await triggerEvent(input, "select");
          await click(".fomio-composer-format");
          await click(
            '.toolbar-menu__fomio-composer-format-content [data-name="bold"]',
          );
          assert
            .dom("textarea.d-editor-input")
            .hasValue("A **quieter** morning");

          await click(".composer-toggle-switch");
          assert.dom(".ProseMirror strong").hasText("quieter");
          const composer = this.container.lookup("service:composer");
          const model = composer.model;
          const documentBefore = model.reply;
          await click(".toggle-minimize");
          await click("#reply-control");
          await settled();
          assert.strictEqual(
            composer.model,
            model,
            "minimize retains the native model",
          );
          assert.strictEqual(
            model.reply,
            documentBefore,
            "minimize retains writing",
          );
          assert.dom(".fomio-composer-format").exists({ count: 1 });

          await click(".composer-toggle-switch");
          assert
            .dom("textarea.d-editor-input")
            .hasValue("A **quieter** morning");
        });
      },
    );
  }
}
