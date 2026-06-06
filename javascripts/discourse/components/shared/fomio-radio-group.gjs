import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import {
  normalizeRadioOptions,
  radioGroupClassNames,
  radioOptionClassNames,
} from "../../lib/fomio-interaction-classes";

export default class FomioRadioGroup extends Component {
  get className() {
    return radioGroupClassNames(this.args);
  }

  get options() {
    return normalizeRadioOptions(this.args).map((option) => ({
      ...option,
      inputId: `${this.groupId}-${String(option.value)}`,
    }));
  }

  get legend() {
    return this.args.label ?? this.args.legend ?? null;
  }

  get name() {
    return this.args.name ?? "fomio-radio-group";
  }

  get groupId() {
    return this.args.id ?? this.name;
  }

  @action
  optionClass(option) {
    return radioOptionClassNames(option, this.args);
  }

  @action
  selectOption(option) {
    if (option.isDisabled) {
      return;
    }

    this.args.onSelect?.(option.value, option);
    this.args.onChange?.(option.value, option);
  }

  @action
  handleKeydown(option, event) {
    if (event.key !== "ArrowDown" && event.key !== "ArrowRight" && event.key !== "ArrowUp" && event.key !== "ArrowLeft") {
      return;
    }

    event.preventDefault();

    const enabledOptions = this.options.filter((candidate) => !candidate.isDisabled);
    const currentIndex = enabledOptions.findIndex(
      (candidate) => candidate.value === option.value
    );

    if (currentIndex === -1) {
      return;
    }

    const isForward =
      event.key === "ArrowDown" || event.key === "ArrowRight";
    const nextOption = isForward
      ? enabledOptions[currentIndex + 1] ?? enabledOptions[0]
      : enabledOptions[currentIndex - 1] ?? enabledOptions[enabledOptions.length - 1];

    this.selectOption(nextOption);

    if (typeof document !== "undefined") {
      document.getElementById(`${this.groupId}-${String(nextOption.value)}`)?.focus();
    }
  }

  <template>
    <fieldset class={{this.className}} ...attributes>
      {{#if this.legend}}
        <legend class="fomio-radio-group__legend">{{this.legend}}</legend>
      {{/if}}

      <div class="fomio-radio-group__list" role="radiogroup" aria-label={{@ariaLabel}}>
        {{#each this.options as |option|}}
          <label class={{this.optionClass option}}>
            <input
              id={{option.inputId}}
              type="radio"
              name={{this.name}}
              value={{option.value}}
              checked={{option.isSelected}}
              disabled={{option.isDisabled}}
              {{on "change" (fn this.selectOption option)}}
              {{on "keydown" (fn this.handleKeydown option)}}
            />
            <span class="fomio-radio__mark" aria-hidden="true"></span>
            <span class="fomio-radio__copy">
              <span class="fomio-radio__label">{{option.label}}</span>
              {{#if option.description}}
                <span class="fomio-radio__description">{{option.description}}</span>
              {{/if}}
            </span>
          </label>
        {{/each}}
      </div>
    </fieldset>
  </template>
}
