import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DMenu from "discourse/float-kit/components/d-menu";
import DropdownMenu from "discourse/components/dropdown-menu";
import { i18n } from "discourse-i18n";
import FomioPhIcon from "./fomio-ph-icon";

export default class FomioInterfaceColorSelector extends Component {
  @service interfaceColor;
  @tracked isDarkModeActive = false;
  #colorModeObserver = null;

  constructor(owner, args) {
    super(owner, args);
    this.#updateDarkModeState();
    if (typeof MutationObserver !== "undefined" && typeof document !== "undefined") {
      this.#colorModeObserver = new MutationObserver(() => {
        this.#updateDarkModeState();
      });
      this.#colorModeObserver.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ["class"],
      });
    }
  }

  willDestroy() {
    this.#colorModeObserver?.disconnect();
    this.#colorModeObserver = null;
    super.willDestroy(...arguments);
  }

  #updateDarkModeState() {
    if (typeof document === "undefined") {
      return;
    }

    this.isDarkModeActive = document.documentElement.classList.contains(
      "fomio-color-dark"
    );
  }

  get isBinarySwitch() {
    return this.args.variant === "binary";
  }

  get selectorIcon() {
    if (this.isDarkModeActive) {
      return "fomio-ph-moon";
    }

    return "fomio-ph-sun";
  }

  @action
  toggleBinaryMode() {
    if (this.isDarkModeActive) {
      this.interfaceColor.forceLightMode();
    } else {
      this.interfaceColor.forceDarkMode();
    }
  }

  @action
  switchToLight(dMenu) {
    this.interfaceColor.forceLightMode();
    dMenu.close();
  }

  @action
  switchToDark(dMenu) {
    this.interfaceColor.forceDarkMode();
    dMenu.close();
  }

  @action
  switchToAuto(dMenu) {
    this.interfaceColor.useAutoMode();
    dMenu.close();
  }

  <template>
    {{#if this.isBinarySwitch}}
      <button
        type="button"
        class="fomio-interface-color-selector fomio-interface-color-selector--binary fomio-interface-color-selector__trigger fomio-interface-color-selector__trigger--binary"
        role="switch"
        aria-checked={{if this.isDarkModeActive "true" "false"}}
        aria-label={{i18n
          "sidebar.footer.interface_color_selector.aria_label"
          mode=this.interfaceColor.colorMode
        }}
        title={{i18n "sidebar.footer.interface_color_selector.title"}}
        data-current-mode={{this.interfaceColor.colorMode}}
        {{on "click" this.toggleBinaryMode}}
      >
        <FomioPhIcon
          @name={{this.selectorIcon}}
          @size={{16}}
          class="fomio-interface-color-selector__trigger-icon"
        />
        <span class="fomio-switch {{if this.isDarkModeActive "fomio-switch--on"}}" aria-hidden="true">
          <span class="fomio-switch__track">
            <span class="fomio-switch__thumb"></span>
          </span>
        </span>
      </button>
    {{else}}
      <DMenu
        @identifier="interface-color-selector"
        @animated={{false}}
        @ariaLabel={{i18n
          "sidebar.footer.interface_color_selector.aria_label"
          mode=this.interfaceColor.colorMode
        }}
        @title={{i18n "sidebar.footer.interface_color_selector.title"}}
        class="fomio-interface-color-selector"
        data-current-mode={{this.interfaceColor.colorMode}}
      >
        <:trigger as |menu|>
        <button
          type="button"
          class="fomio-interface-color-selector__trigger"
          aria-haspopup="dialog"
          aria-expanded={{if menu.show "true" "false"}}
          aria-label={{i18n
            "sidebar.footer.interface_color_selector.aria_label"
            mode=this.interfaceColor.colorMode
          }}
          title={{i18n "sidebar.footer.interface_color_selector.title"}}
          {{on "click" menu.show}}
        >
          <FomioPhIcon
            @name={{this.selectorIcon}}
            @size={{16}}
            class="fomio-interface-color-selector__trigger-icon"
          />
        </button>
        </:trigger>

        <:content as |dMenu|>
          <DropdownMenu class="fomio-interface-color-selector__menu" as |dropdown|>
            <dropdown.item>
              <button
                type="button"
                class="fomio-interface-color-selector__option interface-color-selector__light-option"
                {{on "click" (fn this.switchToLight dMenu)}}
              >
                <FomioPhIcon @name="fomio-ph-sun" @size={{16}} />
                <span>{{i18n "sidebar.footer.interface_color_selector.light"}}</span>
              </button>
            </dropdown.item>
            <dropdown.item>
              <button
                type="button"
                class="fomio-interface-color-selector__option interface-color-selector__dark-option"
                {{on "click" (fn this.switchToDark dMenu)}}
              >
                <FomioPhIcon @name="fomio-ph-moon" @size={{16}} />
                <span>{{i18n "sidebar.footer.interface_color_selector.dark"}}</span>
              </button>
            </dropdown.item>
            <dropdown.item>
              <button
                type="button"
                class="fomio-interface-color-selector__option interface-color-selector__auto-option"
                {{on "click" (fn this.switchToAuto dMenu)}}
              >
                <FomioPhIcon @name="fomio-ph-circle-half" @size={{16}} />
                <span>{{i18n "sidebar.footer.interface_color_selector.auto"}}</span>
              </button>
            </dropdown.item>
          </DropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
