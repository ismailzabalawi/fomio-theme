import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import FomioPhIcon from "./fomio-ph-icon";

export default class FomioSegmentedControl extends Component {
  get wrapperClass() {
    return this.args.wrapperClass ? `fomio-seg ${this.args.wrapperClass}` : "fomio-seg";
  }

  @action
  buttonClass(option) {
    const classes = ["fomio-seg-btn"];
    if (this.args.buttonClass) {
      classes.push(this.args.buttonClass);
    }
    if (option.isActive) {
      classes.push("active", "is-active");
    }
    return classes.join(" ");
  }

  @action
  selectOption(id) {
    this.args.onSelect?.(id);
  }

  <template>
    <div class={{this.wrapperClass}} role="group" aria-label={{@ariaLabel}}>
      {{#each @options as |option|}}
        <button
          type="button"
          class={{this.buttonClass option}}
          aria-label={{option.ariaLabel}}
          aria-pressed={{if option.isActive "true" "false"}}
          {{on "click" (fn this.selectOption option.id)}}
        >
          {{#if option.phIcon}}
            <FomioPhIcon @name={{option.phIcon}} @size={{16}} />
          {{else if option.icon}}
            {{icon option.icon}}
          {{else}}
            {{option.label}}
          {{/if}}
        </button>
      {{/each}}
    </div>
  </template>
}
