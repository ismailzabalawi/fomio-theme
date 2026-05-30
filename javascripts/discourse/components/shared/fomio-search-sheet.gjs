import Component from "@glimmer/component";
import SearchMenu from "discourse/components/search-menu";
import FomioEphemeralSheet from "./fomio-ephemeral-sheet";

export default class FomioSearchSheet extends Component {
  get variant() {
    return this.args.variant ?? "desktop";
  }

  get inputId() {
    return this.args.searchInputId ?? `fomio-search-sheet-${this.variant}-input`;
  }

  get sheetClass() {
    return `fomio-search-sheet fomio-search-sheet--${this.variant}`;
  }

  get backdropClass() {
    if (this.variant === "desktop") {
      return "fomio-search-sheet__backdrop";
    }
    return null;
  }

  <template>
    <FomioEphemeralSheet
      @isOpen={{@isOpen}}
      @onClose={{@onClose}}
      @ariaLabel="Search Fomio"
      @extraClass={{this.sheetClass}}
      @backdropClass={{this.backdropClass}}
    >
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
