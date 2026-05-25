import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";

export default class FomioSearchInput extends Component {
  get wrapperClass() {
    return this.args.wrapperClass
      ? `fomio-search-wrap ${this.args.wrapperClass}`
      : "fomio-search-wrap";
  }

  get inputClass() {
    return this.args.inputClass
      ? `fomio-input ${this.args.inputClass}`
      : "fomio-input";
  }

  @action
  handleInput(event) {
    this.args.onInput?.(event);
  }

  <template>
    <div class={{this.wrapperClass}}>
      <span class="fomio-search-icon" aria-hidden="true">
        {{icon "magnifying-glass"}}
      </span>
      <input
        type="search"
        class={{this.inputClass}}
        value={{@value}}
        placeholder={{@placeholder}}
        aria-label={{@ariaLabel}}
        {{on "input" this.handleInput}}
      />
    </div>
  </template>
}
