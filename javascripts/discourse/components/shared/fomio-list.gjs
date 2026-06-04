import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";

export default class FomioList extends Component {
  get tagName() {
    return this.args.tag ?? "ul";
  }

  get className() {
    const classes = ["fomio-list"];

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
  }

  <template>
    {{#if (eq this.tagName "div")}}
      <div class={{this.className}} ...attributes>
        {{yield}}
      </div>
    {{else if (eq this.tagName "nav")}}
      <nav class={{this.className}} ...attributes>
        {{yield}}
      </nav>
    {{else if (eq this.tagName "ol")}}
      <ol class={{this.className}} ...attributes>
        {{yield}}
      </ol>
    {{else}}
      <ul class={{this.className}} ...attributes>
        {{yield}}
      </ul>
    {{/if}}
  </template>
}
