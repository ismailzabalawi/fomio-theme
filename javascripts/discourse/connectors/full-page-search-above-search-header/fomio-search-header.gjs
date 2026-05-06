import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioSearchHeader extends Component {
  get title() { return i18n(themePrefix("search_page.title")); }

  <template>
    <div class="fomio-search-pg-header">
      <h1 class="fomio-search-pg-header__title"><em>{{this.title}}</em></h1>
    </div>
  </template>
}
