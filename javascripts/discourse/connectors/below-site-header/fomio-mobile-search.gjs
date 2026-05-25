import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioSearchSheet from "../../components/shared/fomio-search-sheet";
import { isAuthPath } from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMobileSearch extends Component {
  @service router;

  @tracked isTouchShell = false;
  @tracked isSearchSheetOpen = false;
  #unsubscribeTouch = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });
    this._onRouteDidChange = () => this.closeSearchSheet();
    if (typeof this.router?.on === "function") {
      this.router.on("routeDidChange", this._onRouteDidChange);
    }
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    if (typeof this.router?.off === "function" && this._onRouteDidChange) {
      this.router.off("routeDidChange", this._onRouteDidChange);
    }
    super.willDestroy();
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return (
      this.isTouchShell &&
      !isAuthPath(this.currentPath) &&
      !this.currentPath.startsWith("/search")
    );
  }

  get searchLabel() {
    return i18n(themePrefix("sidebar.search_label"));
  }

  get searchHint() {
    return i18n(themePrefix("sidebar.search_hint"));
  }

  @action
  openSearchSheet() {
    this.isSearchSheetOpen = true;
  }

  @action
  closeSearchSheet() {
    this.isSearchSheetOpen = false;
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-mobile-search-row">
        <button
          type="button"
          class="fomio-mobile-search-launcher"
          aria-label={{this.searchLabel}}
          {{on "click" this.openSearchSheet}}
        >
          <span class="fomio-mobile-search-launcher__icon" aria-hidden="true">
            {{icon "magnifying-glass"}}
          </span>
          <span class="fomio-mobile-search-launcher__body">
            <span class="fomio-mobile-search-launcher__title">{{this.searchLabel}}</span>
            <span class="fomio-mobile-search-launcher__hint">{{this.searchHint}}</span>
          </span>
        </button>

        <FomioSearchSheet
          @isOpen={{this.isSearchSheetOpen}}
          @onClose={{this.closeSearchSheet}}
          @variant="mobile"
          @searchInputId="fomio-mobile-search-input"
        />
      </div>
    {{/if}}
  </template>
}
