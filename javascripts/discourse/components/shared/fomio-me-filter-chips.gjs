import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioSegmentedControl from "./fomio-segmented-control";

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
        [
          "#user-content .fomio-owned-notifications__timeline",
          "#user-content .user-notifications-list",
          "#user-content .user-stream",
        ].join(", ")
      ) ?? null
    );
  }

  #countVisible(listEl) {
    if (!listEl) {
      return null;
    }
    if (listEl.classList.contains("fomio-owned-notifications__timeline")) {
      let count = 0;
      for (const row of listEl.querySelectorAll(
        ".fomio-owned-notifications__row"
      )) {
        const style = window.getComputedStyle(row);
        if (style.display !== "none" && style.visibility !== "hidden") {
          count++;
        }
      }
      return count;
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

  get options() {
    return (this.args.filters ?? []).map((filter) => ({
      id: filter.id,
      label: this.chipLabel(filter.labelKey),
      isActive: this.activeId === filter.id,
    }));
  }

  @action
  selectFilter(id) {
    this.activeId = id;
    this.#syncBody();
    this.args.onSelect?.(id);
    if (id === "all") {
      this.#teardownObserver();
    } else {
      this.#setupObserver();
    }
  }

  <template>
    <FomioSegmentedControl
      @wrapperClass="fomio-me-filter-chips"
      @buttonClass="fomio-me-filter-chips__chip"
      @ariaLabel={{this.groupAriaLabel}}
      @options={{this.options}}
      @onSelect={{this.selectFilter}}
    />
    {{#if this.showEmptyState}}
      <p class="fomio-me-filter-chips__empty" role="status">
        {{this.emptyStateLabel}}
      </p>
    {{/if}}
  </template>
}
