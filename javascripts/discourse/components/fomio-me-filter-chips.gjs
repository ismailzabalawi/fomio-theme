import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { on } from "@ember/modifier";

/**
 * In-screen filter chips: toggles `document.body` data-attribute only (no URL change).
 * Clears the attribute in `willDestroy` when the host connector unmounts (e.g. leaving the screen).
 */
export default class FomioMeFilterChips extends Component {
  @tracked activeId;

  constructor() {
    super(...arguments);
    this.activeId = this.args.initialFilterId ?? "all";
    this.#syncBody();
  }

  willDestroy() {
    super.willDestroy();
    document.body.removeAttribute(this.args.dataAttributeName);
  }

  #syncBody() {
    const id = this.activeId;
    if (id === "all") {
      document.body.removeAttribute(this.args.dataAttributeName);
    } else {
      document.body.setAttribute(this.args.dataAttributeName, id);
    }
  }

  get groupAriaLabel() {
    return i18n(themePrefix(this.args.groupLabelKey));
  }

  chipLabel = (labelKey) => {
    return i18n(themePrefix(labelKey));
  };

  @action
  selectFilter(id) {
    this.activeId = id;
    this.#syncBody();
  }

  chipClass = (id) => {
    const base = "fomio-me-filter-chips__chip";
    return this.activeId === id ? `${base} ${base}--active` : base;
  };

  <template>
    <div class="fomio-me-filter-chips" role="group" aria-label={{this.groupAriaLabel}}>
      {{#each @filters as |f|}}
        <button
          type="button"
          class={{this.chipClass f.id}}
          aria-pressed={{if (eq this.activeId f.id) "true" "false"}}
          {{on "click" (fn this.selectFilter f.id)}}
        >
          {{this.chipLabel f.labelKey}}
        </button>
      {{/each}}
    </div>
  </template>
}
