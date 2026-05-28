import Component from "@glimmer/component";
import SearchMenu from "discourse/components/search-menu";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioEphemeralSheet from "./fomio-ephemeral-sheet";

export default class FomioSearchSheet extends Component {
  get variant() {
    return this.args.variant ?? "mobile";
  }

  get inputId() {
    return this.args.searchInputId ?? `fomio-search-sheet-${this.variant}-input`;
  }

  get ariaLabel() {
    return i18n(themePrefix("search_sheet.aria_label"));
  }

  get title() {
    return i18n(themePrefix("search_sheet.title"));
  }

  get subtitle() {
    return i18n(themePrefix("search_sheet.subtitle"));
  }

  get sheetClass() {
    return `fomio-search-sheet fomio-search-sheet--${this.variant}`;
  }

  get panelStyle() {
    if (this.variant !== "desktop") {
      return null;
    }

    return [
      "top: clamp(4.5rem, 10vh, 7.25rem)",
      "left: calc(50vw + (var(--fomio-surface-sidebar-offset) / 2))",
      "right: auto",
      "bottom: auto",
      "transform: translateX(-50%)",
      "width: min(39rem, calc(100vw - var(--fomio-surface-sidebar-offset) - 2.5rem))",
      "max-height: min(76vh, 44rem)",
      "z-index: 1990",
    ].join("; ");
  }

  get backdropStyle() {
    if (this.variant !== "desktop") {
      return null;
    }

    return "z-index: 1980";
  }

  <template>
    <FomioEphemeralSheet
      @isOpen={{@isOpen}}
      @onClose={{@onClose}}
      @ariaLabel={{this.ariaLabel}}
      @extraClass={{this.sheetClass}}
      @panelStyle={{this.panelStyle}}
      @backdropStyle={{this.backdropStyle}}
    >
      <div class="fomio-search-sheet__header">
        <p class="fomio-search-sheet__eyebrow">{{this.title}}</p>
        <p class="fomio-search-sheet__subtitle">{{this.subtitle}}</p>
      </div>

      <div class="fomio-search-sheet__search search-menu">
        <SearchMenu
          @onClose={{@onClose}}
          @inlineResults={{true}}
          @autofocusInput={{true}}
          @location="header"
          @searchInputId={{this.inputId}}
        />
      </div>
    </FomioEphemeralSheet>
  </template>
}
