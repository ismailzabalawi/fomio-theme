import Component from "@glimmer/component";
import SearchMenu from "discourse/components/search-menu";
import FomioCommandPalette from "./fomio-command-palette";
import {
  normalizeSheetVariant,
  searchSheetBackdropClass,
  searchSheetClassNames,
} from "../../lib/fomio-interaction-classes";

export default class FomioSearchSheet extends Component {
  get variant() {
    return normalizeSheetVariant(this.args);
  }

  get inputId() {
    return this.args.searchInputId ?? `fomio-search-sheet-${this.variant}-input`;
  }

  get sheetClass() {
    return searchSheetClassNames(this.args);
  }

  get backdropClass() {
    return searchSheetBackdropClass(this.args);
  }

  get ariaLabel() {
    return this.args.ariaLabel ?? "Search Fomio";
  }

  get inlineResults() {
    return this.args.inlineResults ?? true;
  }

  get autofocusInput() {
    return this.args.autofocusInput ?? true;
  }

  get location() {
    return this.args.location ?? "header";
  }

  <template>
    <FomioCommandPalette
      @open={{@isOpen}}
      @onOpenChange={{@onClose}}
      @onClose={{@onClose}}
      @title={{this.ariaLabel}}
      @extraClass={{this.sheetClass}}
      @backdropClass={{this.backdropClass}}
      as |palette|
    >
      <div class="fomio-search-sheet__content">
        <div class="fomio-search-sheet__search search-menu">
          <SearchMenu
            @onClose={{palette.close}}
            @inlineResults={{this.inlineResults}}
            @autofocusInput={{this.autofocusInput}}
            @location={{this.location}}
            @searchInputId={{this.inputId}}
          />
        </div>
      </div>
    </FomioCommandPalette>
  </template>
}
