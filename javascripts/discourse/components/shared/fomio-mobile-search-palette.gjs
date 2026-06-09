import Component from "@glimmer/component";
import SearchMenu from "discourse/components/search-menu";
import FomioCommandPalette from "./fomio-command-palette";

export default class FomioMobileSearchPalette extends Component {
  get isOpen() {
    return this.args.open ?? this.args.isOpen ?? false;
  }

  get inputId() {
    return this.args.searchInputId ?? "fomio-mobile-search-input";
  }

  <template>
    <FomioCommandPalette
      @open={{this.isOpen}}
      @onOpenChange={{@onOpenChange}}
      @onClose={{@onClose}}
      @title="Search Fomio"
      @extraClass="fomio-mobile-search-palette"
      @backdropClass="fomio-mobile-search-palette__backdrop"
      as |palette|
    >
      <div class="fomio-mobile-search-palette__content">
        <div class="fomio-search-sheet__search search-menu">
          <SearchMenu
            @onClose={{palette.close}}
            @inlineResults={{true}}
            @autofocusInput={{true}}
            @location="header"
            @searchInputId={{this.inputId}}
          />
        </div>
      </div>
    </FomioCommandPalette>
  </template>
}
