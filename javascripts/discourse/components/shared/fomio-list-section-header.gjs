import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";

export default class FomioListSectionHeader extends Component {
  get tagName() {
    return this.args.tag ?? "li";
  }

  get className() {
    return this.args.extraClass
      ? `fomio-list__section-header ${this.args.extraClass}`
      : "fomio-list__section-header";
  }

  <template>
    {{#if (eq this.tagName "div")}}
      <div class={{this.className}} ...attributes>
        {{yield}}
      </div>
    {{else}}
      <li class={{this.className}} ...attributes>
        {{yield}}
      </li>
    {{/if}}
  </template>
}
