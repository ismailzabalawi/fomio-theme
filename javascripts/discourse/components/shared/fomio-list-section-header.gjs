import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";
import { listSectionHeaderClassNames } from "../../lib/fomio-content-classes";

export default class FomioListSectionHeader extends Component {
  get tagName() {
    return this.args.tag ?? "li";
  }

  get className() {
    return listSectionHeaderClassNames(this.args);
  }

  <template>
    {{#if (eq this.tagName "div")}}
      <div class={{this.className}} ...attributes>
        {{#if @title}}
          {{@title}}
        {{else}}
          {{yield}}
        {{/if}}
      </div>
    {{else}}
      <li class={{this.className}} ...attributes>
        {{#if @title}}
          {{@title}}
        {{else}}
          {{yield}}
        {{/if}}
      </li>
    {{/if}}
  </template>
}
