import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { next } from "@ember/runloop";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import icon from "discourse/helpers/d-icon";
import FomioPhIcon from "./fomio-ph-icon";
import {
  dropdownClassNames,
  dropdownPanelClassNames,
  dropdownTriggerClassNames,
  normalizeDropdownItems,
} from "../../lib/fomio-interaction-classes";

const FOCUSABLE_ITEM_SELECTOR =
  ".fomio-dropdown__item:not([aria-disabled='true']):not([disabled])";

export default class FomioDropdown extends Component {
  @tracked internalOpen = this.args.defaultOpen ?? false;
  rootElement = null;

  constructor(owner, args) {
    super(owner, args);

    this._handleDocumentClick = (event) => {
      if (!this.isOpen || !this.rootElement) {
        return;
      }

      if (!this.rootElement.contains(event.target)) {
        this.setOpen(false);
      }
    };

    this._handleDocumentFocusIn = (event) => {
      if (!this.isOpen || !this.rootElement) {
        return;
      }

      if (!this.rootElement.contains(event.target)) {
        this.setOpen(false);
      }
    };

    if (typeof document !== "undefined") {
      document.addEventListener("click", this._handleDocumentClick);
      document.addEventListener("focusin", this._handleDocumentFocusIn);
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);

    if (typeof document !== "undefined") {
      document.removeEventListener("click", this._handleDocumentClick);
      document.removeEventListener("focusin", this._handleDocumentFocusIn);
    }
  }

  get isOpen() {
    return this.args.open ?? this.internalOpen;
  }

  get className() {
    return dropdownClassNames({
      ...this.args,
      isOpen: this.isOpen,
    });
  }

  get triggerClass() {
    return dropdownTriggerClassNames(this.args);
  }

  get panelClass() {
    return dropdownPanelClassNames(this.args);
  }

  get triggerLabel() {
    return this.args.label ?? this.args.triggerLabel ?? "";
  }

  get panelRole() {
    return this.args.panelRole ?? "menu";
  }

  get triggerRole() {
    return this.panelRole === "listbox" ? "listbox" : "menu";
  }

  get items() {
    return normalizeDropdownItems(this.args);
  }

  get itemRole() {
    return this.panelRole === "listbox" ? "option" : "menuitem";
  }

  @action
  registerRoot(element) {
    this.rootElement = element;
  }

  @action
  setOpen(nextOpen) {
    if (this.args.open === undefined) {
      this.internalOpen = nextOpen;
    }

    this.args.onOpenChange?.(nextOpen);

    if (nextOpen) {
      next(this, this.focusFirstItem);
    }
  }

  @action
  toggleOpen(event) {
    event.stopPropagation();
    this.setOpen(!this.isOpen);
  }

  @action
  close() {
    this.setOpen(false);
  }

  @action
  focusFirstItem() {
    const firstItem = this.rootElement?.querySelector(
      this.args.initialFocusSelector ?? FOCUSABLE_ITEM_SELECTOR
    );
    firstItem?.focus();
  }

  @action
  triggerKeydown(event) {
    if (
      event.key === "ArrowDown" ||
      event.key === "Enter" ||
      event.key === " "
    ) {
      event.preventDefault();

      if (!this.isOpen) {
        this.setOpen(true);
      } else {
        this.focusFirstItem();
      }

      event.stopPropagation();
      return;
    }

    if (event.key === "Escape" && this.isOpen) {
      event.preventDefault();
      this.close();
      event.stopPropagation();
    }
  }

  @action
  panelKeydown(event) {
    if (this.args.customPanel) {
      if (event.key === "Escape" || event.key === "Tab") {
        this.close();
        event.stopPropagation();
      }
      return;
    }

    const items = [
      ...(this.rootElement?.querySelectorAll(FOCUSABLE_ITEM_SELECTOR) ?? []),
    ];
    const index = items.indexOf(document.activeElement);

    if (event.key === "ArrowDown") {
      event.preventDefault();
      (items[index + 1] ?? items[0])?.focus();
      event.stopPropagation();
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      (items[index - 1] ?? items[items.length - 1])?.focus();
      event.stopPropagation();
      return;
    }

    if (event.key === "Escape" || event.key === "Tab") {
      this.close();
      event.stopPropagation();
    }
  }

  @action
  selectItem(item, event) {
    if (item.isDisabled || item.isLoading) {
      event?.preventDefault();
      return;
    }

    this.args.onSelect?.(item.value, item);
    this.args.onChange?.(item.value, item);

    if (!item.keepOpen) {
      this.close();
    }
  }

  @action
  itemClass(item) {
    const classes = ["fomio-dropdown__item"];

    if (item.selected) {
      classes.push("fomio-dropdown__item--active");
    }

    if (item.isDanger) {
      classes.push("fomio-dropdown__item--danger");
    }

    if (item.isDisabled) {
      classes.push("fomio-dropdown__item--disabled");
    }

    if (item.isLoading) {
      classes.push("fomio-dropdown__item--loading");
    }

    return classes.join(" ");
  }

  <template>
    <div class={{this.className}} {{didInsert this.registerRoot}} ...attributes>
      {{#if (has-block "trigger")}}
        {{yield
          (hash
            close=this.close
            isOpen=this.isOpen
            toggleOpen=this.toggleOpen
            triggerClass=this.triggerClass
            triggerKeydown=this.triggerKeydown
            triggerRole=this.triggerRole
          )
          to="trigger"
        }}
      {{else}}
        <button
          type="button"
          class={{this.triggerClass}}
          aria-haspopup={{this.triggerRole}}
          aria-expanded={{if this.isOpen "true" "false"}}
          {{on "click" this.toggleOpen}}
          {{on "keydown" this.triggerKeydown}}
        >
          {{#if @leadingIcon}}
            {{icon @leadingIcon}}
          {{/if}}
          {{this.triggerLabel}}
          {{#if @trailingIcon}}
            {{icon @trailingIcon}}
          {{/if}}
        </button>
      {{/if}}

      <div
        class={{this.panelClass}}
        role={{this.panelRole}}
        aria-hidden={{if this.isOpen "false" "true"}}
        {{on "keydown" this.panelKeydown}}
      >
        {{#if (has-block "panel")}}
          {{yield (hash close=this.close isOpen=this.isOpen) to="panel"}}
        {{else}}
          {{#each this.items as |item|}}
            {{#if item.isDivider}}
              <div class="fomio-dropdown__divider" role="separator"></div>
            {{else if item.isSection}}
              <div class="fomio-dropdown__section-label">{{item.label}}</div>
            {{else if item.href}}
              <a
                href={{item.href}}
                class={{this.itemClass item}}
                role={{this.itemRole}}
                aria-disabled={{if item.isUnavailable "true"}}
                aria-selected={{if item.selected "true" "false"}}
                {{on "click" (fn this.selectItem item)}}
              >
                {{#if item.phIcon}}
                  <FomioPhIcon @name={{item.phIcon}} @size={{16}} />
                {{else if item.icon}}
                  {{icon item.icon}}
                {{/if}}
                <span>{{item.label}}</span>
                {{#if item.trailingIcon}}
                  {{icon item.trailingIcon}}
                {{/if}}
              </a>
            {{else}}
              <button
                type="button"
                class={{this.itemClass item}}
                role={{this.itemRole}}
                disabled={{item.isUnavailable}}
                aria-disabled={{if item.isUnavailable "true"}}
                aria-selected={{if item.selected "true" "false"}}
                {{on "click" (fn this.selectItem item)}}
              >
                {{#if item.phIcon}}
                  <FomioPhIcon @name={{item.phIcon}} @size={{16}} />
                {{else if item.icon}}
                  {{icon item.icon}}
                {{/if}}
                <span>{{item.label}}</span>
                {{#if item.trailingIcon}}
                  {{icon item.trailingIcon}}
                {{/if}}
              </button>
            {{/if}}
          {{/each}}
        {{/if}}
      </div>
    </div>
  </template>
}
