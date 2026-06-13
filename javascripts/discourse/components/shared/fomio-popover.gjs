import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { popoverClassNames } from "../../lib/fomio-interaction-classes";

// Layer 3 (Interaction) — small contextual overlay anchored to a trigger.
// Holds a short title, body, and optional confirm/cancel actions — lighter than
// fomio-modal (no backdrop, no focus trap). Positioning is the consumer's job;
// pass placement via ...attributes/wrapper. Display-only: consumers own open
// state and pass action handlers.
//
// Props: @open/@isOpen, @align (start|end), @title, @body, @dismissible,
// @closeLabel, @confirmLabel, @cancelLabel, @onConfirm, @onCancel, @onClose.

export default class FomioPopover extends Component {
  get isOpen() {
    return this.args.open ?? this.args.isOpen ?? true;
  }

  get className() {
    return popoverClassNames(this.args);
  }

  get ariaLabel() {
    return this.args.ariaLabel ?? this.args.title ?? "Popover";
  }

  get dismissible() {
    return this.args.dismissible ?? false;
  }

  get closeLabel() {
    return this.args.closeLabel ?? "Close";
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
        class={{this.className}}
        role="dialog"
        aria-label={{this.ariaLabel}}
        ...attributes
      >
        {{#if this.dismissible}}
          <button
            type="button"
            class="fomio-popover__close"
            aria-label={{this.closeLabel}}
            {{on "click" this.requestClose}}
          >
            {{icon "times"}}
          </button>
        {{/if}}

        {{#if @title}}
          <p class="fomio-popover__title">{{@title}}</p>
        {{/if}}

        {{#if @body}}
          <p class="fomio-popover__body">{{@body}}</p>
        {{/if}}

        {{yield}}

        {{#if this.hasActions}}
          <div class="fomio-popover__actions">
            {{#if @cancelLabel}}
              <button
                type="button"
                class="fomio-btn fomio-btn-secondary fomio-btn--sm"
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
                  "fomio-btn fomio-btn-danger fomio-btn--sm"
                  "fomio-btn fomio-btn-primary fomio-btn--sm"
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
