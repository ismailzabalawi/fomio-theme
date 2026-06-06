import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import FomioPhIcon from "./fomio-ph-icon";
import {
  normalizedSegmentedOptions,
  segmentedButtonClassNames,
  segmentedWrapperClassNames,
} from "../../lib/fomio-interaction-classes";

export default class FomioSegmentedControl extends Component {
  get wrapperClass() {
    return segmentedWrapperClassNames(this.args);
  }

  get options() {
    return normalizedSegmentedOptions(this.args);
  }

  get role() {
    return this.args.role ?? "group";
  }

  @action
  buttonClass(option) {
    return segmentedButtonClassNames(option, this.args);
  }

  @action
  selectOption(option) {
    if (option.isDisabled) {
      return;
    }

    this.args.onSelect?.(option.value, option);
    this.args.onChange?.(option.value, option);
  }

  <template>
    <div class={{this.wrapperClass}} role={{this.role}} aria-label={{@ariaLabel}}>
      {{#each this.options as |option|}}
        <button
          type="button"
          class={{this.buttonClass option}}
          aria-label={{option.ariaLabel}}
          aria-pressed={{if option.isActive "true" "false"}}
          disabled={{option.isDisabled}}
          aria-disabled={{if option.isDisabled "true"}}
          {{on "click" (fn this.selectOption option)}}
        >
          {{#if option.phIcon}}
            <FomioPhIcon @name={{option.phIcon}} @size={{16}} />
          {{else if option.icon}}
            {{icon option.icon}}
          {{/if}}
          {{#if option.label}}
            {{option.label}}
          {{/if}}
        </button>
      {{/each}}
    </div>
  </template>
}
