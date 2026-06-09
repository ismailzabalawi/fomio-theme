import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { getOwner } from "@ember/owner";
import FomioSearchInput from "../../components/shared/fomio-search-input";
import FomioButton from "../../components/shared/fomio-button";

export default class FomioBookmarkSearch extends Component {
  @service router;

  get bookmarksController() {
    // Try to get controller from outlet args first, then lookup
    return this.args.controller ||
           getOwner(this)?.lookup("controller:user-activity.bookmarks");
  }

  @action
  handleSearchInputChange(event) {
    // Update controller's search term as user types
    const value = event.target.value;
    const controller = this.bookmarksController;
    if (controller) {
      // Set the internal _searchTerm that the search() action uses
      controller.set("_searchTerm", value);
    }
  }

  @action
  handleSearchKeydown(event) {
    // Trigger search on Enter key
    if (event.key === "Enter") {
      event.preventDefault();
      this.handleSearchSubmit();
    }
  }

  @action
  handleSearchSubmit() {
    // Trigger search on button click or Enter key
    const controller = this.bookmarksController;
    if (controller) {
      // Ensure _searchTerm is set before calling search
      if (!controller._searchTerm) {
        controller.set("_searchTerm", this.currentSearchTerm);
      }
      // Call the search action
      controller.send("search");
    }
  }

  get currentSearchTerm() {
    return this.bookmarksController?.searchTerm ?? "";
  }

  get isBookmarksPage() {
    return this.router.currentURL.includes("/activity/bookmarks") ||
           this.router.currentURL.includes("/bookmarks");
  }

  <template>
    {{#if this.isBookmarksPage}}
      {{! Custom Fomio bookmark search form — replaces native Discourse form }}
      <div class="fomio-bookmark-search-wrapper">
        <div class="fomio-bookmark-search-form">
          <FomioSearchInput
            @value={{this.currentSearchTerm}}
            @onChange={{this.handleSearchInputChange}}
            @placeholder="Search bookmarks by name, topic title, or post content"
            {{on "keydown" this.handleSearchKeydown}}
          />
          <FomioButton
            @variant="primary"
            @size="base"
            @leadingIcon="magnifying-glass"
            class="fomio-bookmark-search__button"
            {{on "click" this.handleSearchSubmit}}
          >
            Search
          </FomioButton>
        </div>
      </div>
    {{/if}}
  </template>
}
