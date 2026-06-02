import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import {
  computeChecks,
  progressPct,
  readTimeMinutes,
} from "../../lib/fomio-composer-metrics";
import {
  jumpToOutline,
  metricsStore,
} from "../../lib/fomio-composer-metrics-store";

/**
 * Connector: composer-after-composer-editor
 *
 * Right rail for the full-page Create / Edit surface: live word count, read
 * time, progress toward the recommended length, a heading outline, and
 * editorial checks. Reads the reactive metrics store (written by the PM
 * metrics extension) and derives display values through the pure, unit-tested
 * metrics lib. Renders nothing for replies.
 */
export default class FomioComposerRail extends Component {
  get model() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    const model = this.model;
    return Boolean(model && (model.creatingTopic || model.editingPost));
  }

  get words() {
    return metricsStore.words;
  }

  get wordsLabel() {
    return metricsStore.words.toLocaleString();
  }

  get readTime() {
    return readTimeMinutes(metricsStore.words);
  }

  get progress() {
    return progressPct(metricsStore.words);
  }

  get outline() {
    return metricsStore.outline;
  }

  get activeOutlinePos() {
    return metricsStore.activeOutlinePos;
  }

  get checks() {
    return computeChecks({
      title: this.model?.title,
      categoryId: this.model?.categoryId,
      chars: metricsStore.chars,
    });
  }

  @action
  jumpTo(item) {
    if (!item || typeof item.pos !== "number") {
      return;
    }
    jumpToOutline(item.pos);
  }

  isActive(item) {
    return Boolean(
      item &&
        Number.isFinite(item.pos) &&
        item.pos === this.activeOutlinePos
    );
  }

  <template>
    {{#if this.shouldRender}}
      <aside class="fomio-composer-rail">
        <section class="fomio-composer-rail__section">
          <h4>{{i18n (themePrefix "composer.rail_draft")}}</h4>
          <div class="fomio-composer-rail__meter">
            <div class="fomio-composer-rail__stat">
              <b>{{this.wordsLabel}}</b>
              <span>{{i18n (themePrefix "composer.words")}}</span>
            </div>
            <div class="fomio-composer-rail__stat">
              <b>{{this.readTime}} {{i18n (themePrefix "composer.min")}}</b>
              <span>{{i18n (themePrefix "composer.read")}}</span>
            </div>
            <div class="fomio-composer-rail__bar">
              <div
                class="fomio-composer-rail__bar-fill"
                style="width: {{this.progress}}%"
              ></div>
            </div>
            <div class="fomio-composer-rail__hint">
              {{i18n (themePrefix "composer.word_range")}}
            </div>
          </div>
        </section>

        {{#if this.outline.length}}
          <section class="fomio-composer-rail__section">
            <h4>{{i18n (themePrefix "composer.rail_outline")}}</h4>
            <div class="fomio-composer-rail__outline">
              {{#each this.outline as |item|}}
                <button
                  type="button"
                  class="fomio-composer-rail__out is-h{{item.level}}
                    {{if (this.isActive item) "is-active"}}"
                  aria-label={{i18n (themePrefix "composer.outline_jump_to")}}
                  aria-current={{if (this.isActive item) "true"}}
                  {{on "click" (fn this.jumpTo item)}}
                >{{item.text}}</button>
              {{/each}}
            </div>
          </section>
        {{/if}}

        <section class="fomio-composer-rail__section">
          <h4>{{i18n (themePrefix "composer.rail_checks")}}</h4>
          <div class="fomio-composer-rail__checks">
            <span
              class="fomio-composer-rail__check
                {{if this.checks.titleSet 'is-done'}}"
            >
              {{#if this.checks.titleSet}}{{icon "check"}}{{else}}{{icon
                  "circle"
                }}{{/if}}
              {{i18n (themePrefix "composer.check_title")}}
            </span>
            <span
              class="fomio-composer-rail__check
                {{if this.checks.teretChosen 'is-done'}}"
            >
              {{#if this.checks.teretChosen}}{{icon "check"}}{{else}}{{icon
                  "circle"
                }}{{/if}}
              {{i18n (themePrefix "composer.check_teret")}}
            </span>
            <span
              class="fomio-composer-rail__check
                {{if this.checks.minLength 'is-done'}}"
            >
              {{#if this.checks.minLength}}{{icon "check"}}{{else}}{{icon
                  "circle"
                }}{{/if}}
              {{i18n (themePrefix "composer.check_length")}}
            </span>
          </div>
        </section>
      </aside>
    {{/if}}
  </template>
}
