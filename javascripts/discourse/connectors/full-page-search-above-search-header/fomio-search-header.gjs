import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

const SEARCH_OPERATORS =
  /\b(?:order|in|with|status|min_replies|min_posts|max_posts|min_views|max_views|before|after|user|category|tags?):\S+\b/g;

export default class FomioSearchHeader extends Component {
  get searchTerm() {
    return this.args.outletArgs?.searchTerm ?? "";
  }

  get displayTerm() {
    const cleaned = this.searchTerm
      .replace(SEARCH_OPERATORS, "")
      .replace(/\s+/g, " ")
      .trim();

    return cleaned || this.searchTerm.trim();
  }

  get isEmpty() {
    return !this.searchTerm.trim();
  }

  <template>
    {{#if this.isEmpty}}
      <header class="fomio-search-hd fomio-search-hd--empty">
        <span class="fomio-search-hd__eyebrow">
          {{i18n (themePrefix "search_page.heading_pre")}}
        </span>
        <h1 class="fomio-search-hd__display">{{i18n
            (themePrefix "search_page.heading_display")
          }}</h1>
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
          <em>"{{this.displayTerm}}"</em>
        </h1>
      </header>
    {{/if}}
  </template>
}
