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

export default class FomioSelect extends Component {
  get fieldClass() {
    return fieldClassNames("fomio-field", this.args);
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

  get labelClass() {
    return fieldLabelClassNames("fomio-field-label", this.args);
  }

  get hintClass() {
    return fieldHintClassNames(this.args);
  }

  get errorClass() {
    return fieldHintClassNames(this.args, "error");
  }

  @action
  handleChange(event) {
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

        <select
          class={{this.inputClass}}
          value={{@value}}
          disabled={{this.isDisabled}}
          {{on "change" this.handleChange}}
          ...attributes
        >
          {{#if @placeholder}}
            <option value="">{{@placeholder}}</option>
          {{/if}}

          {{#if @options}}
            {{#each @options as |option|}}
              <option value={{option.value}} disabled={{option.disabled}}>
                {{option.label}}
              </option>
            {{/each}}
          {{else}}
            {{yield}}
          {{/if}}
        </select>

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
