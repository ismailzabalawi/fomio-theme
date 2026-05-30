import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import FomioMobileSearchPalette from "../../components/shared/fomio-mobile-search-palette";
import { isAuthPath } from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMobileSearch extends Component {
  @service router;

  @tracked isTouchShell = false;
  @tracked isSearchSheetOpen = false;
  #unsubscribeTouch = null;
  #searchButtonClickHandler = null;
  #prevFocusEl = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });
    this._onRouteDidChange = () => {
      this.closeSearchSheet();
    };
    if (typeof this.router?.on === "function") {
      this.router.on("routeDidChange", this._onRouteDidChange);
    }
    this.#searchButtonClickHandler = (event) => {
      if (!this.shouldRender) {
        return;
      }

      const trigger = event.target?.closest?.("#search-button");
      if (!trigger) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation?.();
      if (this.isSearchSheetOpen) {
        this.closeSearchSheet();
        return;
      }
      this.#prevFocusEl = trigger;
      this.openSearchSheet();
    };

    if (typeof document !== "undefined") {
      document.addEventListener("click", this.#searchButtonClickHandler, true);
    }
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    if (typeof document !== "undefined") {
      if (this.#searchButtonClickHandler) {
        document.removeEventListener(
          "click",
          this.#searchButtonClickHandler,
          true
        );
      }
      document.body.style.overflow = "";
    }
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

  @action
  openSearchSheet(event) {
    event?.preventDefault();
    this.isSearchSheetOpen = true;
    if (typeof document !== "undefined") {
      document.body.style.overflow = "hidden";
    }
  }

  @action
  closeSearchSheet() {
    this.isSearchSheetOpen = false;
    if (typeof document !== "undefined") {
      document.body.style.overflow = "";
    }
    this.#prevFocusEl?.focus?.();
    this.#prevFocusEl = null;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioMobileSearchPalette
        @isOpen={{this.isSearchSheetOpen}}
        @onClose={{this.closeSearchSheet}}
        @searchInputId="fomio-mobile-search-input"
      />
    {{/if}}
  </template>
}
