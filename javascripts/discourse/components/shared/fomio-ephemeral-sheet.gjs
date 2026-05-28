import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Ephemeral sheet: backdrop + panel. Parent owns open state; when closed,
 * do not render (keeps content out of the accessibility tree).
 */
export default class FomioEphemeralSheet extends Component {
  get closeLabel() {
    return i18n(themePrefix("ephemeral_sheet.close_label"));
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
    }
  }

  @action
  onCloseClick() {
    this.args.onClose?.();
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
