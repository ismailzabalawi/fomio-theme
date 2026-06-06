import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import icon from "discourse/helpers/d-icon";
import { toastClassNames } from "../../lib/fomio-interaction-classes";

const TONE_ICONS = {
  neutral: "info-circle",
  success: "check-circle",
  warning: "exclamation-triangle",
  danger: "times-circle",
};

export default class FomioToast extends Component {
  timeoutId = null;

  get isOpen() {
    return this.args.open ?? this.args.isOpen ?? true;
  }

  get className() {
    return toastClassNames(this.args);
  }

  get role() {
    return this.args.tone === "danger" ? "alert" : "status";
  }

  get liveMode() {
    return this.role === "alert" ? "assertive" : "polite";
  }

  get iconName() {
    if (this.args.icon === false) {
      return null;
    }

    return this.args.icon ?? TONE_ICONS[this.args.tone ?? "neutral"];
  }

  get dismissible() {
    return this.args.dismissible !== false;
  }

  get dismissLabel() {
    return this.args.dismissLabel ?? "Dismiss notification";
  }

  get hasActions() {
    return Boolean(this.args.actionLabel || this.dismissible);
  }

  @action
  setupTimer() {
    const duration = this.args.duration ?? this.args.autoDismissMs;

    if (!duration || duration <= 0 || typeof window === "undefined") {
      return;
    }

    this.clearTimer();
    this.timeoutId = window.setTimeout(() => this.dismiss(), duration);
  }

  @action
  clearTimer() {
    if (this.timeoutId && typeof window !== "undefined") {
      window.clearTimeout(this.timeoutId);
    }

    this.timeoutId = null;
  }

  @action
  dismiss() {
    this.clearTimer();
    this.args.onDismiss?.();
    this.args.onOpenChange?.(false);
  }

  <template>
    {{#if this.isOpen}}
      <div
        class={{this.className}}
        role={{this.role}}
        aria-live={{this.liveMode}}
        {{didInsert this.setupTimer}}
        {{willDestroy this.clearTimer}}
        ...attributes
      >
        {{#if this.iconName}}
          <span class="fomio-toast__icon" aria-hidden="true">
            {{icon this.iconName}}
          </span>
        {{/if}}

        <div class="fomio-toast__content">
          {{#if @title}}
            <div class="fomio-toast__title">{{@title}}</div>
          {{/if}}

          {{#if @message}}
            <div class="fomio-toast__message">{{@message}}</div>
          {{/if}}

          {{yield}}
        </div>

        {{#if this.hasActions}}
          <div class="fomio-toast__actions">
            {{#if @actionLabel}}
              <button
                type="button"
                class="fomio-toast__action"
                {{on "click" @onAction}}
              >
                {{@actionLabel}}
              </button>
            {{/if}}

            {{#if this.dismissible}}
              <button
                type="button"
                class="fomio-toast__dismiss"
                aria-label={{this.dismissLabel}}
                {{on "click" this.dismiss}}
              >
                {{icon "times"}}
              </button>
            {{/if}}
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
