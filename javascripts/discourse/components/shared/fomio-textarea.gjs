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

export default class FomioTextarea extends Component {
  get fieldClass() {
    return fieldClassNames("fomio-textarea", this.args);
  }

  get wrapClass() {
    return wrapClassNames("fomio-input-wrap", this.iconArgs);
  }

  get inputClass() {
    return inputClassNames(this.iconArgs, ["fomio-textarea__field"]);
  }

  get iconArgs() {
    return {
      ...this.args,
      trailingIcon: this.trailingIcon,
    };
  }

  get isDisabled() {
    return isControlDisabled(this.args);
  }

  get rows() {
    return this.args.rows ?? 4;
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

  get labelClass() {
    return fieldLabelClassNames("fomio-textarea__label", this.args);
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

        <textarea
          class={{this.inputClass}}
          value={{@value}}
          disabled={{this.isDisabled}}
          rows={{this.rows}}
          placeholder={{@placeholder}}
          aria-label={{@ariaLabel}}
          {{on "input" this.handleInput}}
          ...attributes
        ></textarea>

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
