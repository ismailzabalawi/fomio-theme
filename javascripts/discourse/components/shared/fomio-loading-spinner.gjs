import Component from "@glimmer/component";

// Layer 3 (Interaction) — animated loading spinner for use in buttons,
// in-progress states, and other feedback contexts. Displays when @isLoading
// is true. Display-only: consumers pass @isLoading state.
//
// Props: @isLoading, @size (sm|md|lg), @tone (default|accent|danger).

export default class FomioLoadingSpinner extends Component {
  get isLoading() {
    return this.args.isLoading ?? this.args.loading ?? false;
  }

  get size() {
    return this.args.size ?? "md";
  }

  get tone() {
    return this.args.tone ?? this.args.variant ?? "default";
  }

  get className() {
    const classes = ["fomio-spinner"];

    if (this.size && this.size !== "md") {
      classes.push(`fomio-spinner--${this.size}`);
    }

    if (this.tone && this.tone !== "default") {
      classes.push(`fomio-spinner--${this.tone}`);
    }

    return classes.join(" ");
  }

  <template>
    {{#if this.isLoading}}
      <span class={{this.className}} aria-hidden="true" role="status">
        <svg
          class="fomio-spinner__svg"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <circle
            class="fomio-spinner__circle"
            cx="12"
            cy="12"
            r="10"
            fill="none"
            stroke-width="2"
            stroke-linecap="round"
          ></circle>
        </svg>
      </span>
    {{/if}}
  </template>
}
