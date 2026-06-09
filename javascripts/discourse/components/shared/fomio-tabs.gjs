import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { normalizeTabs } from "../../lib/fomio-interaction-classes";

export default class FomioTabs extends Component {
  idPrefix =
    this.args.idPrefix ??
    `fomio-tabs-${Math.random().toString(36).slice(2, 8)}`;

  @tracked internalSelectedKey =
    this.args.defaultSelectedKey ?? this.args.selectedKey ?? null;

  get resolvedSelectedKey() {
    return this.args.selectedKey ?? this.internalSelectedKey;
  }

  get tabs() {
    return normalizeTabs({
      ...this.args,
      idPrefix: this.idPrefix,
      selectedKey: this.resolvedSelectedKey,
    });
  }

  get className() {
    const classes = ["fomio-tabs"];

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
  }

  @action
  setSelectedKey(key, tab) {
    if (tab.isDisabled) {
      return;
    }

    if (this.args.selectedKey === undefined) {
      this.internalSelectedKey = key;
    }

    this.args.onSelect?.(key, tab);
    this.args.onChange?.(key, tab);
  }

  @action
  selectTab(tab) {
    this.setSelectedKey(tab.key, tab);
  }

  @action
  onTabKeydown(tab, event) {
    const enabledTabs = this.tabs.filter((candidate) => !candidate.isDisabled);
    const currentIndex = enabledTabs.findIndex(
      (candidate) => candidate.key === tab.key
    );

    if (currentIndex === -1) {
      return;
    }

    let nextTab = null;

    if (event.key === "ArrowRight") {
      nextTab = enabledTabs[currentIndex + 1] ?? enabledTabs[0];
    } else if (event.key === "ArrowLeft") {
      nextTab =
        enabledTabs[currentIndex - 1] ?? enabledTabs[enabledTabs.length - 1];
    } else if (event.key === "Home") {
      nextTab = enabledTabs[0];
    } else if (event.key === "End") {
      nextTab = enabledTabs[enabledTabs.length - 1];
    } else {
      return;
    }

    event.preventDefault();
    this.setSelectedKey(nextTab.key, nextTab);
    if (typeof document !== "undefined") {
      document.getElementById(nextTab.triggerId)?.focus();
    }
    event.stopPropagation();
  }

  <template>
    <div class={{this.className}} data-fomio-managed="true" ...attributes>
      <div class="fomio-tabs__list" role="tablist" aria-label={{@ariaLabel}}>
        {{#each this.tabs as |tab|}}
          <button
            id={{tab.triggerId}}
            type="button"
            class="fomio-tabs__trigger"
            role="tab"
            aria-selected={{if tab.isSelected "true" "false"}}
            aria-controls={{tab.panelId}}
            disabled={{tab.isDisabled}}
            tabindex={{if tab.isSelected "0" "-1"}}
            {{on "click" (fn this.selectTab tab)}}
            {{on "keydown" (fn this.onTabKeydown tab)}}
          >
            {{tab.label}}
            {{#if tab.badge}}
              <span class="fomio-tabs__trigger-badge">{{tab.badge}}</span>
            {{/if}}
          </button>
        {{/each}}
      </div>

      {{#each this.tabs as |tab|}}
        <div
          id={{tab.panelId}}
          class={{if
            tab.isSelected
            "fomio-tabs__panel fomio-tabs__panel--active"
            "fomio-tabs__panel"
          }}
          role="tabpanel"
          aria-labelledby={{tab.triggerId}}
          aria-hidden={{if tab.isSelected "false" "true"}}
        >
          {{#if (has-block)}}
            {{yield tab}}
          {{else}}
            {{tab.content}}
          {{/if}}
        </div>
      {{/each}}
    </div>
  </template>
}
