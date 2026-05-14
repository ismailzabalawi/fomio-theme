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
 *
 * Empty state: when a non-"all" filter is active and no visible list items remain,
 * a status message is shown. Detected via MutationObserver on the list container.
 *
 * Known limitation: Discourse's "Load more" pagination fetches new rows without
 * applying the CSS filter — this is an architectural constraint of CSS-only filtering.
 */
export default class FomioMeFilterChips extends Component {
  @tracked activeId;
  @tracked visibleCount = null;

  #listObserver = null;
  #listEl = null;

  constructor() {
    super(...arguments);
    this.activeId = this.args.initialFilterId ?? "all";
    this.#syncBody();
  }

  willDestroy() {
    super.willDestroy();
    this.#teardownObserver();
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

  #findListEl() {
    return (
      document.querySelector(
        `#user-content .user-notifications-list, #user-content .user-stream`
      ) ?? null
    );
  }

  #countVisible(listEl) {
    if (!listEl) {
      return null;
    }
    let count = 0;
    for (const child of listEl.children) {
      const style = window.getComputedStyle(child);
      if (style.display !== "none" && style.visibility !== "hidden") {
        count++;
      }
    }
    return count;
  }

  #setupObserver() {
    this.#teardownObserver();
    this.#listEl = this.#findListEl();
    if (!this.#listEl) {
      return;
    }
    this.visibleCount = this.#countVisible(this.#listEl);
    this.#listObserver = new MutationObserver(() => {
      this.visibleCount = this.#countVisible(this.#listEl);
    });
    this.#listObserver.observe(this.#listEl, {
      childList: true,
      subtree: false,
      attributes: true,
      attributeFilter: ["style", "class"],
    });
  }

  #teardownObserver() {
    this.#listObserver?.disconnect();
    this.#listObserver = null;
    this.#listEl = null;
    this.visibleCount = null;
  }

  get showEmptyState() {
    return (
      this.activeId !== "all" &&
      this.visibleCount !== null &&
      this.visibleCount === 0
    );
  }

  get groupAriaLabel() {
    return i18n(themePrefix(this.args.groupLabelKey));
  }

  get emptyStateLabel() {
    return i18n(themePrefix("me_filter_chips.notifications.empty"));
  }

  chipLabel = (labelKey) => {
    return i18n(themePrefix(labelKey));
  };

  @action
  selectFilter(id) {
    this.activeId = id;
    this.#syncBody();
    if (id === "all") {
      this.#teardownObserver();
    } else {
      this.#setupObserver();
    }
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
    {{#if this.showEmptyState}}
      <p class="fomio-me-filter-chips__empty" role="status">
        {{this.emptyStateLabel}}
      </p>
    {{/if}}
  </template>
}
