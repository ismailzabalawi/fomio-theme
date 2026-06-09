import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import {
  buttonClassNames,
  isControlDisabled,
} from "../../lib/fomio-control-classes";

export default class FomioButton extends Component {
  get className() {
    return buttonClassNames(this.args);
  }

  get isLink() {
    return Boolean(this.args.href);
  }

  get buttonType() {
    return this.args.type ?? "button";
  }

  get isDisabled() {
    return isControlDisabled(this.args);
  }

  get href() {
    if (this.isDisabled) {
      return null;
    }

    return this.args.href;
  }

  <template>
    {{#if this.isLink}}
      <a
        href={{this.href}}
        class={{this.className}}
        aria-disabled={{if this.isDisabled "true"}}
        ...attributes
      >
        {{#if @leadingIcon}}
          {{icon @leadingIcon}}
        {{/if}}
        {{yield}}
        {{#if @trailingIcon}}
          {{icon @trailingIcon}}
        {{/if}}
      </a>
    {{else}}
      <button
        type={{this.buttonType}}
        class={{this.className}}
        disabled={{this.isDisabled}}
        ...attributes
      >
        {{#if @leadingIcon}}
          {{icon @leadingIcon}}
        {{/if}}
        {{yield}}
        {{#if @trailingIcon}}
          {{icon @trailingIcon}}
        {{/if}}
      </button>
    {{/if}}
  </template>
}
