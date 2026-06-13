import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";

// Layer 1 (Control) — toggle switch for boolean settings.
// Display-only: consumers own @checked state and pass @onChange callback.
// Accessibility: uses `role="switch"` and `aria-checked` for semantic meaning.
//
// Props: @checked, @disabled, @onChange, @label, @ariaLabel.

export default class FomioSwitch extends Component {
  get isChecked() {
    return this.args.checked ?? this.args.value ?? false;
  }

  get isDisabled() {
    return this.args.disabled ?? false;
  }

  get ariaLabel() {
    return this.args.ariaLabel ?? this.args.label ?? "Toggle";
  }

  @action
  toggle() {
    if (this.isDisabled) {
      return;
    }

    this.args.onChange?.(!this.isChecked);
  }

  <template>
    <button
      type="button"
      role="switch"
      aria-checked={{this.isChecked}}
      aria-label={{this.ariaLabel}}
      disabled={{this.isDisabled}}
      class={{if this.isChecked "fomio-switch fomio-switch--on" "fomio-switch"}}
      {{on "click" this.toggle}}
      ...attributes
    >
      <span class="fomio-switch__track" aria-hidden="true">
        <span class="fomio-switch__thumb"></span>
      </span>
    </button>
  </template>
}
