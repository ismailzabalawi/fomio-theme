import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";

// Layer 2 (Content) — small circular icon container used in settings rows,
// list items, and other compact contexts. Holds a single icon with colored
// background. Tone determines the background color (accent, danger, info, etc.).
//
// Props: @icon (icon name or false to suppress), @tone (accent|danger|info|success|warning),
// @size (sm|md|lg).

const TONE_ICONS = {
  accent: "circle",
  danger: "exclamation-circle",
  info: "info-circle",
  success: "check-circle",
  warning: "exclamation-triangle",
};

export default class FomioIconPill extends Component {
  get tone() {
    return this.args.tone ?? this.args.variant ?? "accent";
  }

  get size() {
    return this.args.size ?? "md";
  }

  get className() {
    const classes = ["fomio-icon-pill"];

    if (this.size && this.size !== "md") {
      classes.push(`fomio-icon-pill--${this.size}`);
    }

    if (this.tone) {
      classes.push(`fomio-icon-pill--${this.tone}`);
    }

    return classes.join(" ");
  }

  get iconName() {
    if (this.args.icon === false) {
      return null;
    }

    return this.args.icon ?? TONE_ICONS[this.tone];
  }

  <template>
    <span class={{this.className}} aria-hidden="true" ...attributes>
      {{#if this.iconName}}
        {{icon this.iconName}}
      {{/if}}
    </span>
  </template>
}
