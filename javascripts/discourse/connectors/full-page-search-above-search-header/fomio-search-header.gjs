import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioSearchHeader extends Component {
  get searchTerm() {
    return this.args.outletArgs?.searchTerm ?? "";
  }

  get isEmpty() {
    return !this.searchTerm.trim();
  }

  <template>
    {{#if this.isEmpty}}
      <header class="fomio-search-hd fomio-search-hd--empty">
        <h1 class="fomio-search-hd__display">
          {{i18n (themePrefix "search_page.heading_pre")}}
          <span class="fomio-search-hd__mark">
            {{i18n (themePrefix "search_page.heading_brand")}}<span
              class="fomio-search-hd__arc"
              aria-hidden="true"
            ></span>
          </span>
        </h1>
        <p class="fomio-search-hd__deck">
          {{i18n (themePrefix "search_page.deck")}}
        </p>
      </header>
    {{else}}
      <header class="fomio-search-hd fomio-search-hd--active">
        <span class="fomio-search-hd__eyebrow">
          {{i18n (themePrefix "search_page.results_label")}}
        </span>
        <h1 class="fomio-search-hd__title">
          {{i18n (themePrefix "search_page.results_for")}}
          <em>"{{this.searchTerm}}"</em>
        </h1>
      </header>
    {{/if}}
  </template>
}
