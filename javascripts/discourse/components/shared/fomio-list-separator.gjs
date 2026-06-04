import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";

export default class FomioListSeparator extends Component {
  get tagName() {
    return this.args.tag ?? "li";
  }

  get className() {
    const classes = ["fomio-list__separator"];

    if (this.args.inset) {
      classes.push("fomio-list__separator--inset");
    }

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
  }

  <template>
    {{#if (eq this.tagName "div")}}
      <div class={{this.className}} aria-hidden="true" ...attributes></div>
    {{else}}
      <li class={{this.className}} aria-hidden="true" ...attributes></li>
    {{/if}}
  </template>
}
