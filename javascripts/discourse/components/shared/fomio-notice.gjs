import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { noticeClassNames } from "../../lib/fomio-interaction-classes";

// Layer 3 (Interaction) — inline, in-flow status message.
// Tones: info (default), success, warning, danger. Pairs a leading tone icon
// with a message and an optional dismiss button. Display-only: consumers own
// open state and pass @onDismiss. For full-width page-level messaging use
// fomio-banner; for transient feedback use fomio-toast.
//
// Props: @tone, @icon (name or false to suppress), @message (or yielded body),
// @dismissible, @dismissLabel, @onDismiss.

const TONE_ICONS = {
  info: "info-circle",
  success: "check-circle",
  warning: "exclamation-triangle",
  danger: "times-circle",
};

export default class FomioNotice extends Component {
  get tone() {
    return this.args.tone ?? this.args.variant ?? "info";
  }

  get className() {
    return noticeClassNames({ ...this.args, dismissible: this.dismissible });
  }

  get role() {
    return this.tone === "danger" || this.tone === "warning" ? "alert" : "status";
  }

  get iconName() {
    if (this.args.icon === false) {
      return null;
    }

    return this.args.icon ?? TONE_ICONS[this.tone] ?? TONE_ICONS.info;
  }

  get dismissible() {
    return this.args.dismissible ?? Boolean(this.args.onDismiss);
  }

  get dismissLabel() {
    return this.args.dismissLabel ?? "Dismiss";
  }

  @action
  dismiss() {
    this.args.onDismiss?.();
    this.args.onOpenChange?.(false);
  }

  <template>
    <div class={{this.className}} role={{this.role}} ...attributes>
      {{#if this.iconName}}
        <span class="fomio-notice__icon" aria-hidden="true">
          {{icon this.iconName}}
        </span>
      {{/if}}

      <div class="fomio-notice__content">
        {{#if @title}}
          <div class="fomio-notice__title">{{@title}}</div>
        {{/if}}

        {{#if @message}}
          <div class="fomio-notice__message">{{@message}}</div>
        {{/if}}

        {{yield}}
      </div>

      {{#if this.dismissible}}
        <button
          type="button"
          class="fomio-notice__dismiss"
          aria-label={{this.dismissLabel}}
          {{on "click" this.dismiss}}
        >
          {{icon "times"}}
        </button>
      {{/if}}
    </div>
  </template>
}
