import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";
import { cardClassNames } from "../../lib/fomio-content-classes";

export default class FomioCard extends Component {
  get tagName() {
    return this.args.tag ?? (this.args.href ? "a" : "div");
  }

  get className() {
    return cardClassNames(this.args);
  }

  get buttonType() {
    return this.args.type ?? "button";
  }

  <template>
    {{#if (eq this.tagName "a")}}
      <a href={{@href}} class={{this.className}} ...attributes>
        {{yield}}
      </a>
    {{else if (eq this.tagName "article")}}
      <article class={{this.className}} ...attributes>
        {{yield}}
      </article>
    {{else if (eq this.tagName "section")}}
      <section class={{this.className}} ...attributes>
        {{yield}}
      </section>
    {{else if (eq this.tagName "button")}}
      <button
        type={{this.buttonType}}
        class={{this.className}}
        disabled={{@disabled}}
        aria-disabled={{if @disabled "true"}}
        ...attributes
      >
        {{yield}}
      </button>
    {{else}}
      <div class={{this.className}} ...attributes>
        {{yield}}
      </div>
    {{/if}}
  </template>
}
