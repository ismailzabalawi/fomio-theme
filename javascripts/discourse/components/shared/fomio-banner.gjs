import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { bannerClassNames } from "../../lib/fomio-interaction-classes";

// Layer 3 (Interaction) — full-width, page-level announcement bar.
// Tones: info (default), success, warning, danger. Spans the surface to flag
// system-wide state (read-only mode, scheduled maintenance, account flags).
// Display-only: consumers own open state and pass @onDismiss. For in-flow
// contextual messages use fomio-notice; for transient feedback use fomio-toast.
//
// Props: @tone, @icon (name or false to suppress), @message (or yielded body),
// @actionLabel, @onAction, @dismissible, @dismissLabel, @onDismiss.

const TONE_ICONS = {
  info: "info-circle",
  success: "check-circle",
  warning: "exclamation-triangle",
  danger: "times-circle",
};

export default class FomioBanner extends Component {
  get tone() {
    return this.args.tone ?? this.args.variant ?? "info";
  }

  get className() {
    return bannerClassNames({ ...this.args, dismissible: this.dismissible });
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
        <span class="fomio-banner__icon" aria-hidden="true">
          {{icon this.iconName}}
        </span>
      {{/if}}

      <div class="fomio-banner__content">
        {{#if @message}}{{@message}}{{/if}}
        {{yield}}
      </div>

      {{#if @actionLabel}}
        <button
          type="button"
          class="fomio-banner__action"
          {{on "click" @onAction}}
        >
          {{@actionLabel}}
        </button>
      {{/if}}

      {{#if this.dismissible}}
        <button
          type="button"
          class="fomio-banner__dismiss"
          aria-label={{this.dismissLabel}}
          {{on "click" this.dismiss}}
        >
          {{icon "times"}}
        </button>
      {{/if}}
    </div>
  </template>
}
