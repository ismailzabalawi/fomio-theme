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

  <template>
    <FomioEphemeralSheet
      @isOpen={{@isOpen}}
      @onClose={{@onClose}}
      @ariaLabel={{this.ariaLabel}}
      @extraClass={{this.sheetClass}}
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
