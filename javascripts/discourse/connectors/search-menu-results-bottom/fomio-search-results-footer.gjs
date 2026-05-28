import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioSearchResultsFooter extends Component {
  @service search;

  get term() {
    return this.search.activeGlobalSearchTerm?.trim();
  }

  get shouldRender() {
    return Boolean(this.term);
  }

  get label() {
    return i18n(themePrefix("search_sheet.see_all_results"));
  }

  get href() {
    let url = "/search";
    const params = new URLSearchParams();

    if (this.term) {
      let q = this.term;
      if (this.search.searchContext?.type === "topic") {
        q += ` topic:${this.search.searchContext.id}`;
      } else if (this.search.searchContext?.type === "private_messages") {
        q += " in:messages";
      }
      params.set("q", q);
    }

    if (params.toString()) {
      url = `${url}?${params}`;
    }

    return getURL(url);
  }

  @action
  openFullSearch(event) {
    event?.preventDefault();
    this.args.outletArgs.closeSearchMenu?.();
    DiscourseURL.routeTo(this.href);
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-search-results-footer">
        <a
          href={{this.href}}
          class="fomio-search-results-footer__link"
          {{on "click" this.openFullSearch}}
        >
          {{this.label}}
        </a>
      </div>
    {{/if}}
  </template>
}
