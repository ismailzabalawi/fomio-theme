import Component from "@glimmer/component";
import SearchMenu from "discourse/components/search-menu";

export default class FomioGlobalSearch extends Component {
  get variant() {
    return this.args.variant ?? "sidebar";
  }

  get inputId() {
    return this.args.searchInputId ?? `fomio-${this.variant}-search-input`;
  }

  get classNames() {
    return `fomio-global-search fomio-global-search--${this.variant} search-menu`;
  }

  <template>
    <div class={{this.classNames}} aria-live="polite" ...attributes>
      <SearchMenu
        @location="header"
        @searchInputId={{this.inputId}}
        @searchInputPlaceholder={{@searchInputPlaceholder}}
      />
    </div>
  </template>
}
