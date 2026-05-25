import Component from "@glimmer/component";

const VARIANT_CLASSES = {
  primary: "fomio-btn-primary",
  secondary: "fomio-btn-secondary",
  ghost: "fomio-btn-ghost",
  danger: "fomio-btn-danger",
};

export default class FomioButton extends Component {
  get className() {
    const classes = ["fomio-btn"];
    classes.push(VARIANT_CLASSES[this.args.variant] || VARIANT_CLASSES.primary);

    if (this.args.size === "sm") {
      classes.push("fomio-btn--sm");
    } else if (this.args.size === "lg") {
      classes.push("fomio-btn--lg");
    }

    if (this.args.block) {
      classes.push("fomio-btn--block");
    }

    if (this.args.iconOnly) {
      classes.push("fomio-btn--icon");
    }

    if (this.args.isLoading) {
      classes.push("is-loading");
    }

    if (this.args.isActive) {
      classes.push("is-active");
    }

    if (this.args.isOpen) {
      classes.push("is-open");
    }

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
  }

  get buttonType() {
    return this.args.type ?? "button";
  }

  get isDisabled() {
    return Boolean(this.args.disabled || this.args.isLoading);
  }

  <template>
    <button
      type={{this.buttonType}}
      class={{this.className}}
      disabled={{this.isDisabled}}
      ...attributes
    >
      {{yield}}
    </button>
  </template>
}
