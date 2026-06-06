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

  get buttonType() {
    return this.args.type ?? "button";
  }

  get isDisabled() {
    return isControlDisabled(this.args);
  }

  <template>
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
  </template>
}
