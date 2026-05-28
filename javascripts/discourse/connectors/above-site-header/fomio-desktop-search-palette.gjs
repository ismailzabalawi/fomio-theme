import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { next } from "@ember/runloop";
import FomioSearchSheet from "../../components/shared/fomio-search-sheet";
import {
  closeDesktopSearchPalette,
  openDesktopSearchPalette,
  subscribeDesktopSearchPalette,
} from "../../lib/fomio-desktop-search-palette";
import { isAuthPath } from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

function isEditableTarget(element) {
  if (!element) {
    return false;
  }

  if (element.isContentEditable) {
    return true;
  }

  if (element.closest?.("#reply-control, .d-editor, .ProseMirror")) {
    return true;
  }

  const tagName = element.tagName?.toLowerCase?.();
  return ["input", "textarea", "select"].includes(tagName);
}

export default class FomioDesktopSearchPalette extends Component {
  @service router;
  @service search;

  @tracked isTouchShell = false;
  @tracked isSearchSheetOpen = false;
  #unsubscribeTouch = null;
  #unsubscribePalette = null;
  #keydownHandler = null;

  constructor(owner, args) {
    super(owner, args);

    this.#unsubscribeTouch = subscribeFomioTouchShell((value) => {
      this.isTouchShell = value;
      if (value) {
        closeDesktopSearchPalette();
      }
    });

    this.#unsubscribePalette = subscribeDesktopSearchPalette((isOpen) => {
      this.isSearchSheetOpen = isOpen;
      if (isOpen) {
        this.focusSearchInput();
      }
    });

    this._onRouteDidChange = () => {
      this.closeSearchSheet();
    };
    if (typeof this.router?.on === "function") {
      this.router.on("routeDidChange", this._onRouteDidChange);
    }

    this.#keydownHandler = (event) => {
      if (!this.shouldRender) {
        return;
      }

      if (!(event.metaKey || event.ctrlKey) || event.altKey) {
        return;
      }

      if (event.code !== "Slash") {
        return;
      }

      const target = event.target;
      const activeElement = document.activeElement;
      if (isEditableTarget(target) || isEditableTarget(activeElement)) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();
      if (this.isSearchSheetOpen) {
        this.focusSearchInput();
      } else {
        openDesktopSearchPalette();
      }
    };

    if (typeof document !== "undefined") {
      document.addEventListener("keydown", this.#keydownHandler, true);
    }
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    this.#unsubscribePalette?.();

    if (typeof document !== "undefined" && this.#keydownHandler) {
      document.removeEventListener("keydown", this.#keydownHandler, true);
    }

    if (typeof this.router?.off === "function" && this._onRouteDidChange) {
      this.router.off("routeDidChange", this._onRouteDidChange);
    }

    super.willDestroy(...arguments);
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return !this.isTouchShell && !isAuthPath(this.currentPath);
  }

  get desktopSearchInputId() {
    return this.search.currentSearchInputId;
  }

  focusSearchInput() {
    next(() => {
      document.getElementById(this.desktopSearchInputId)?.focus();
    });
  }

  @action
  closeSearchSheet() {
    closeDesktopSearchPalette();
  }

  <template>
    {{#if this.shouldRender}}
      <FomioSearchSheet
        @isOpen={{this.isSearchSheetOpen}}
        @onClose={{this.closeSearchSheet}}
        @variant="desktop"
        @searchInputId={{this.desktopSearchInputId}}
      />
    {{/if}}
  </template>
}
