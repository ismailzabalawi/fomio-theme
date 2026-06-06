import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import {
  fieldClassNames,
  fieldHintClassNames,
  fieldLabelClassNames,
  inputClassNames,
  isControlDisabled,
  isControlLoading,
  wrapClassNames,
} from "../../lib/fomio-control-classes";

export default class FomioInput extends Component {
  get fieldClass() {
    return fieldClassNames("fomio-field", this.args);
  }

  get labelClass() {
    return fieldLabelClassNames("fomio-field-label", this.args);
  }

  get wrapClass() {
    return wrapClassNames("fomio-input-wrap", this.iconArgs);
  }

  get inputClass() {
    return inputClassNames(this.iconArgs);
  }

  get iconArgs() {
    return {
      ...this.args,
      trailingIcon: this.trailingIcon,
    };
  }

  get inputType() {
    return this.args.type ?? "text";
  }

  get isDisabled() {
    return isControlDisabled(this.args);
  }

  get trailingIcon() {
    if (isControlLoading(this.args)) {
      return "spinner";
    }

    return this.args.trailingIcon ?? null;
  }

  get trailingIconClass() {
    const classes = ["fomio-input-icon", "suffix", "static"];

    if (isControlLoading(this.args)) {
      classes.push("is-loading");
    }

    return classes.join(" ");
  }

  get hintClass() {
    return fieldHintClassNames(this.args);
  }

  get errorClass() {
    return fieldHintClassNames(this.args, "error");
  }

  @action
  handleInput(event) {
    this.args.onInput?.(event);
    this.args.onChange?.(event);
  }

  <template>
    <div class={{this.fieldClass}}>
      {{#if @label}}
        <label class={{this.labelClass}} for={{@id}}>
          {{@label}}
        </label>
      {{/if}}

      <div class={{this.wrapClass}}>
        {{#if @leadingIcon}}
          <span class="fomio-input-icon prefix static" aria-hidden="true">
            {{icon @leadingIcon}}
          </span>
        {{/if}}

        <input
          type={{this.inputType}}
          class={{this.inputClass}}
          value={{@value}}
          placeholder={{@placeholder}}
          aria-label={{@ariaLabel}}
          disabled={{this.isDisabled}}
          {{on "input" this.handleInput}}
          ...attributes
        />

        {{#if this.trailingIcon}}
          <span class={{this.trailingIconClass}} aria-hidden="true">
            {{icon this.trailingIcon}}
          </span>
        {{/if}}
      </div>

      {{#if @hint}}
        <div class={{this.hintClass}}>{{@hint}}</div>
      {{/if}}
      {{#if @error}}
        <div class={{this.errorClass}}>{{@error}}</div>
      {{/if}}
    </div>
  </template>
}
