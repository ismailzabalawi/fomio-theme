import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import icon from "discourse/helpers/d-icon";
import {
  modalBackdropClassNames,
  modalClassNames,
} from "../../lib/fomio-interaction-classes";

const FOCUSABLE_SELECTORS =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

export default class FomioModal extends Component {
  get isOpen() {
    return this.args.open ?? this.args.isOpen ?? false;
  }

  get dialogClass() {
    return modalClassNames(this.args);
  }

  get backdropClass() {
    return modalBackdropClassNames(this.args);
  }

  get closeOnBackdrop() {
    return this.args.closeOnBackdrop ?? true;
  }

  get closeOnEscape() {
    return this.args.closeOnEscape ?? true;
  }

  get dismissible() {
    return this.args.dismissible ?? true;
  }

  get ariaLabel() {
    return this.args.ariaLabel ?? this.args.title ?? "Dialog";
  }

  get closeLabel() {
    return this.args.closeLabel ?? "Close dialog";
  }

  get hasActions() {
    return Boolean(this.args.confirmLabel || this.args.cancelLabel);
  }

  @action
  requestClose() {
    this.args.onClose?.();
    this.args.onOpenChange?.(false);
  }

  @action
  onBackdropClick() {
    if (this.dismissible && this.closeOnBackdrop) {
      this.requestClose();
    }
  }

  @action
  onKeydown(event) {
    if (event.key === "Escape" && this.dismissible && this.closeOnEscape) {
      event.preventDefault();
      this.requestClose();
      return;
    }

    if (event.key !== "Tab") {
      return;
    }

    const dialog = event.currentTarget;
    const focusable = [...dialog.querySelectorAll(FOCUSABLE_SELECTORS)].filter(
      (element) => getComputedStyle(element).display !== "none"
    );

    if (!focusable.length) {
      return;
    }

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (event.shiftKey) {
      if (document.activeElement === first || document.activeElement === dialog) {
        event.preventDefault();
        last.focus();
      }
    } else if (document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  }

  @action
  setupDialog(element) {
    element.focus();
  }

  @action
  confirm() {
    this.args.onConfirm?.();
  }

  @action
  cancel() {
    this.args.onCancel?.();
    this.requestClose();
  }

  <template>
    {{#if this.isOpen}}
      <div
        class={{this.backdropClass}}
        aria-hidden="true"
        {{on "click" this.onBackdropClick}}
      ></div>
      <div
        class={{this.dialogClass}}
        role="dialog"
        aria-modal="true"
        aria-label={{this.ariaLabel}}
        tabindex="-1"
        {{didInsert this.setupDialog}}
        {{on "keydown" this.onKeydown}}
      >
        <div class="fomio-modal__header">
          {{#if @title}}
            <h2 class="fomio-modal__title">{{@title}}</h2>
          {{/if}}

          {{#if this.dismissible}}
            <button
              type="button"
              class="fomio-modal__close"
              aria-label={{this.closeLabel}}
              {{on "click" this.requestClose}}
            >
              {{icon "times"}}
            </button>
          {{/if}}
        </div>

        {{#if @body}}
          <p class="fomio-modal__body">{{@body}}</p>
        {{/if}}

        <div class="fomio-modal__content">
          {{yield}}
        </div>

        {{#if this.hasActions}}
          <div class="fomio-modal__actions">
            {{#if @cancelLabel}}
              <button
                type="button"
                class="fomio-btn fomio-btn-secondary"
                {{on "click" this.cancel}}
              >
                {{@cancelLabel}}
              </button>
            {{/if}}

            {{#if @confirmLabel}}
              <button
                type="button"
                class={{if
                  @danger
                  "fomio-btn fomio-btn-danger"
                  "fomio-btn fomio-btn-primary"
                }}
                {{on "click" this.confirm}}
              >
                {{@confirmLabel}}
              </button>
            {{/if}}
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
