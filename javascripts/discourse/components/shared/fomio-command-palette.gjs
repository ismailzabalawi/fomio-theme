import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import icon from "discourse/helpers/d-icon";
import FomioSearchInput from "./fomio-search-input";
import FomioEmptyState from "./fomio-empty-state";
import {
  commandPaletteBackdropClassNames,
  commandPaletteClassNames,
  normalizeCommandItems,
} from "../../lib/fomio-interaction-classes";

const FOCUSABLE_SELECTORS =
  'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])';

function normalizeSearchTerm(value) {
  return (value ?? "").trim().toLowerCase();
}

export default class FomioCommandPalette extends Component {
  @tracked searchTerm = "";
  @tracked activeIndex = 0;

  get isOpen() {
    return this.args.open ?? this.args.isOpen ?? false;
  }

  get className() {
    return commandPaletteClassNames(this.args);
  }

  get backdropClass() {
    return commandPaletteBackdropClassNames(this.args);
  }

  get title() {
    return this.args.title ?? "Command palette";
  }

  get searchPlaceholder() {
    return this.args.searchPlaceholder ?? "Search actions";
  }

  get emptyTitle() {
    return this.args.emptyTitle ?? "No matching actions";
  }

  get emptyBody() {
    return this.args.emptyBody ?? "Try a different keyword.";
  }

  get allItems() {
    return normalizeCommandItems(this.args);
  }

  get visibleItems() {
    const term = normalizeSearchTerm(this.searchTerm);
    if (!term) {
      return this.allItems;
    }

    const result = [];
    let pendingSection = null;
    let pendingDivider = null;

    for (const item of this.allItems) {
      if (item.isSection) {
        pendingSection = item;
        pendingDivider = null;
        continue;
      }

      if (item.isDivider) {
        pendingDivider = item;
        continue;
      }

      if (!item.searchText.includes(term)) {
        continue;
      }

      if (pendingSection) {
        result.push(pendingSection);
        pendingSection = null;
      }

      if (pendingDivider && result[result.length - 1]?.key !== pendingDivider.key) {
        result.push(pendingDivider);
      }

      pendingDivider = null;
      result.push(item);
    }

    return result;
  }

  get actionableItems() {
    return this.visibleItems.filter(
      (item) => !item.isSection && !item.isDivider && !item.isDisabled
    );
  }

  get activeItemKey() {
    return this.actionableItems[this.activeIndex]?.key ?? null;
  }

  get hasResults() {
    return this.actionableItems.length > 0;
  }

  @action
  setupPalette(element) {
    const input = element.querySelector("input[type='search'], input");
    if (input) {
      input.focus();
      return;
    }

    element.focus();
  }

  @action
  requestClose() {
    this.searchTerm = "";
    this.activeIndex = 0;
    this.args.onClose?.();
    this.args.onOpenChange?.(false);
  }

  @action
  onBackdropClick() {
    this.requestClose();
  }

  @action
  updateSearch(event) {
    this.searchTerm = event.target.value;
    this.activeIndex = 0;
  }

  @action
  onKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.requestClose();
      return;
    }

    if (event.key === "Tab") {
      const palette = event.currentTarget;
      const focusable = [...palette.querySelectorAll(FOCUSABLE_SELECTORS)].filter(
        (element) => getComputedStyle(element).display !== "none"
      );

      if (!focusable.length) {
        return;
      }

      const first = focusable[0];
      const last = focusable[focusable.length - 1];

      if (event.shiftKey) {
        if (document.activeElement === first || document.activeElement === palette) {
          event.preventDefault();
          last.focus();
        }
      } else if (document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }

      return;
    }

    if (!this.hasResults) {
      return;
    }

    if (event.key === "ArrowDown") {
      event.preventDefault();
      this.activeIndex =
        this.activeIndex + 1 >= this.actionableItems.length
          ? 0
          : this.activeIndex + 1;
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      this.activeIndex =
        this.activeIndex - 1 < 0
          ? this.actionableItems.length - 1
          : this.activeIndex - 1;
      return;
    }

    if (event.key === "Enter") {
      const activeItem = this.actionableItems[this.activeIndex];

      if (activeItem) {
        event.preventDefault();
        this.selectItem(activeItem);
      }
    }
  }

  @action
  selectItem(item) {
    if (item.isDisabled) {
      return;
    }

    this.args.onSelect?.(item.value, item);
    this.args.onAction?.(item.value, item);

    if (item.href && typeof window !== "undefined") {
      window.location.assign(item.href);
    }

    this.requestClose();
  }

  @action
  itemClass(item) {
    const classes = ["fomio-command-palette__item"];

    if (item.key === this.activeItemKey) {
      classes.push("is-active");
    }

    if (item.isDisabled) {
      classes.push("is-disabled");
    }

    return classes.join(" ");
  }

  <template>
    {{#if this.isOpen}}
      <div
        class={{this.backdropClass}}
        aria-hidden="true"
        {{on "click" this.onBackdropClick}}
      ></div>
      <div
        class={{this.className}}
        role="dialog"
        aria-modal="true"
        aria-label={{this.title}}
        tabindex="-1"
        {{didInsert this.setupPalette}}
        {{on "keydown" this.onKeydown}}
      >
        {{#if (has-block)}}
          {{yield (hash close=this.requestClose)}}
        {{else}}
          <div class="fomio-command-palette__search">
            <FomioSearchInput
              @value={{this.searchTerm}}
              @placeholder={{this.searchPlaceholder}}
              @onInput={{this.updateSearch}}
              @trailingIcon="search"
              @leadingIcon={{null}}
              @wrapperClass="fomio-command-palette__search-wrap"
              @inputClass="fomio-command-palette__search-input"
            />
          </div>

          <div class="fomio-command-palette__results">
            {{#if this.hasResults}}
              {{#each this.visibleItems as |item|}}
                {{#if item.isSection}}
                  <div class="fomio-command-palette__section">{{item.label}}</div>
                {{else if item.isDivider}}
                  <div class="fomio-command-palette__divider" role="separator"></div>
                {{else}}
                  <button
                    type="button"
                    class={{this.itemClass item}}
                    disabled={{item.isDisabled}}
                    {{on "click" (fn this.selectItem item)}}
                  >
                    {{#if item.icon}}
                      <span class="fomio-command-palette__item-icon" aria-hidden="true">
                        {{icon item.icon}}
                      </span>
                    {{/if}}

                    <span class="fomio-command-palette__item-copy">
                      <span class="fomio-command-palette__item-label">{{item.label}}</span>
                      {{#if item.subtitle}}
                        <span class="fomio-command-palette__item-subtitle">{{item.subtitle}}</span>
                      {{/if}}
                    </span>

                    {{#if item.shortcut}}
                      <kbd class="fomio-command-palette__shortcut">{{item.shortcut}}</kbd>
                    {{/if}}
                  </button>
                {{/if}}
              {{/each}}
            {{else}}
              <FomioEmptyState
                @variant="inline"
                @icon="magnifying-glass"
                @title={{this.emptyTitle}}
                @body={{this.emptyBody}}
              />
            {{/if}}
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
