import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

const FOCUSABLE_SELECTORS =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

/**
 * Ephemeral sheet: backdrop + panel. Parent owns open state; when closed,
 * do not render (keeps content out of the accessibility tree).
 */
export default class FomioEphemeralSheet extends Component {
  #sheetElement = null;
  #viewportCleanup = null;

  get closeLabel() {
    return i18n(themePrefix("ephemeral_sheet.close_label"));
  }

  willDestroy() {
    this.teardownSheet();
    super.willDestroy(...arguments);
  }

  @action
  onBackdropClick() {
    this.args.onClose?.();
  }

  @action
  onKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.args.onClose?.();
      return;
    }

    if (event.key === "Tab") {
      const sheet = event.currentTarget;
      const focusable = [
        ...sheet.querySelectorAll(FOCUSABLE_SELECTORS),
      ].filter((el) => getComputedStyle(el).display !== "none");
      if (!focusable.length) {
        return;
      }
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey) {
        if (
          document.activeElement === first ||
          document.activeElement === sheet
        ) {
          event.preventDefault();
          last.focus();
        }
      } else {
        if (document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      }
    }
  }

  @action
  onCloseClick() {
    this.args.onClose?.();
  }

  @action
  setupSheet(element) {
    this.teardownSheet();
    this.#sheetElement = element;

    if (typeof window === "undefined") {
      return;
    }

    const sync = () => this.syncViewportMetrics(element);
    const viewport = window.visualViewport;

    if (viewport) {
      viewport.addEventListener("resize", sync);
      viewport.addEventListener("scroll", sync);
    }

    window.addEventListener("orientationchange", sync);
    document.addEventListener("focusin", sync, true);
    document.addEventListener("focusout", sync, true);

    this.#viewportCleanup = () => {
      if (viewport) {
        viewport.removeEventListener("resize", sync);
        viewport.removeEventListener("scroll", sync);
      }
      window.removeEventListener("orientationchange", sync);
      document.removeEventListener("focusin", sync, true);
      document.removeEventListener("focusout", sync, true);
    };

    sync();
  }

  @action
  teardownSheet() {
    this.#viewportCleanup?.();
    this.#viewportCleanup = null;

    if (this.#sheetElement) {
      this.#sheetElement.style.removeProperty("--fomio-ephemeral-keyboard-offset");
      this.#sheetElement.style.removeProperty("--fomio-ephemeral-viewport-height");
    }

    this.#sheetElement = null;
  }

  syncViewportMetrics(element) {
    if (
      !element ||
      typeof window === "undefined" ||
      !document.body?.classList.contains("fomio-surface-touch")
    ) {
      return;
    }

    const viewport = window.visualViewport;
    if (!viewport) {
      element.style.removeProperty("--fomio-ephemeral-keyboard-offset");
      element.style.removeProperty("--fomio-ephemeral-viewport-height");
      return;
    }

    const viewportHeight = Math.max(0, Math.round(viewport.height));
    const viewportOffsetTop = Math.max(0, Math.round(viewport.offsetTop || 0));
    const occludedBottom = Math.max(
      0,
      Math.round(window.innerHeight - (viewportHeight + viewportOffsetTop))
    );
    const keyboardOffset = occludedBottom > 80 ? occludedBottom : 0;

    element.style.setProperty(
      "--fomio-ephemeral-keyboard-offset",
      `${keyboardOffset}px`
    );
    element.style.setProperty(
      "--fomio-ephemeral-viewport-height",
      `${viewportHeight}px`
    );
  }

  <template>
    {{#if @isOpen}}
      <div
        class="fomio-ephemeral-sheet-backdrop {{@backdropClass}}"
        aria-hidden="true"
        {{on "click" this.onBackdropClick}}
      ></div>
      <div
        class="fomio-ephemeral-sheet {{@extraClass}}"
        role="dialog"
        aria-modal="true"
        aria-label={{@ariaLabel}}
        tabindex="-1"
        {{didInsert this.setupSheet}}
        {{willDestroy this.teardownSheet}}
        {{on "keydown" this.onKeydown}}
      >
        <div class="fomio-ephemeral-sheet__inner">
          {{yield}}
        </div>
        <button
          type="button"
          class="fomio-ephemeral-sheet__close"
          {{on "click" this.onCloseClick}}
        >
          {{this.closeLabel}}
        </button>
      </div>
    {{/if}}
  </template>
}
