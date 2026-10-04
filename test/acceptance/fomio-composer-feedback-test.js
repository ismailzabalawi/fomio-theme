import { click, settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { i18n } from "discourse-i18n";

const MESSAGE = ".fomio-composer-feedback__message";

// Requires development Discourse at the pinned commit. These exercise the
// native model/outlet, not a separate composer simulation or real drafts.
for (const mobile of [false, true]) {
  for (const redesign of [false, true]) {
    acceptance(
      `Fomio | Composer feedback mobile=${mobile} redesign=${redesign}`,
      function (needs) {
        let failDraftSaves = false;
        needs.hooks.beforeEach(() => {
          failDraftSaves = false;
        });
        needs.pretender((server, helper) => {
          server.post("/drafts.json", () =>
            failDraftSaves
              ? helper.response(503, {})
              : helper.response({ draft_sequence: 1 }),
          );
        });
        needs.user();
        needs.settings({
          enable_composer_redesign: redesign,
          allow_uncategorized_topics: true,
        });
        if (mobile) {
          needs.mobileView();
        }

        for (const rich of [false, true]) {
          test(`offline warning follows native status without changing writing or closing rich=${rich}`, async function (assert) {
            await visit("/latest");
            await click("#create-topic");
            if (rich) {
              await click(".composer-toggle-switch");
            }
            const composer = this.container.lookup("service:composer");
            const model = composer.model;
            const initialState = model.composeState;
            failDraftSaves = true;
            model.set("reply", "Keep this writing in the native editor.");
            await model.saveDraft();
            await settled();

            assert.dom(MESSAGE).exists({ count: 1 });
            assert
              .dom(`${MESSAGE} > .fomio-composer-feedback__text > span`)
              .hasText(i18n("composer.drafts_offline"));
            assert
              .dom(`${MESSAGE} p`)
              .hasText(i18n(themePrefix("composer.unsaved_close_warning")));
            assert
              .dom(".fomio-composer-feedback")
              .hasAttribute("aria-live", "polite");
            assert.strictEqual(
              model.reply,
              "Keep this writing in the native editor.",
            );
            assert.strictEqual(model.composeState, initialState);

            failDraftSaves = false;
            await model.saveDraft();
            await settled();
            assert
              .dom(MESSAGE)
              .doesNotExist("native recovery clears the warning");
            assert.strictEqual(
              model.reply,
              "Keep this writing in the native editor.",
            );
          });
        }

        test("conflicts retain native text without an offline instruction", async function (assert) {
          await visit("/latest");
          await click("#create-topic");
          this.container
            .lookup("service:composer")
            .model.set("draftStatus", i18n("composer.edit_conflict"));
          await settled();
          if (mobile) {
            assert.dom(MESSAGE).hasText(i18n("composer.edit_conflict"));
          } else {
            assert
              .dom(MESSAGE)
              .doesNotExist("desktop already renders native conflict text");
          }
          assert.dom(`${MESSAGE} p`).doesNotExist();
        });

        test("category search retains the native field and gains a descriptive name", async function (assert) {
          await visit("/latest");
          await click("#create-topic");
          const chooser = selectKit("#reply-control .category-chooser");
          await chooser.expand();
          const input = "#reply-control .category-chooser input.filter-input";
          assert
            .dom(input)
            .hasAttribute(
              "aria-label",
              i18n(themePrefix("composer.search_categories")),
            );
          await chooser.fillInFilter("general");
          assert
            .dom(input)
            .hasValue("general", "native filtering remains editable");
        });
      },
    );
  }
}
