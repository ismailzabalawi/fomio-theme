import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import SearchMenu from "discourse/components/search-menu";

export default class FomioMobileSearchPalette extends Component {
  @action
  onBackdropClick() {
    this.args.onClose?.();
  }

  @action
  onKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.args.onClose?.();
    }
  }

  get inputId() {
    return this.args.searchInputId ?? "fomio-mobile-search-input";
  }

  <template>
    {{#if @isOpen}}
      <div
        class="fomio-mobile-search-palette__backdrop"
        aria-hidden="true"
        {{on "click" this.onBackdropClick}}
      ></div>
      <div
        class="fomio-mobile-search-palette"
        role="dialog"
        aria-modal="true"
        aria-label="Search Fomio"
        tabindex="-1"
        {{on "keydown" this.onKeydown}}
      >
        <div class="fomio-mobile-search-palette__surface">
          <div class="fomio-mobile-search-palette__inner">
            <div class="fomio-search-sheet__search search-menu">
              <SearchMenu
                @onClose={{@onClose}}
                @inlineResults={{true}}
                @autofocusInput={{true}}
                @location="header"
                @searchInputId={{this.inputId}}
              />
            </div>
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
