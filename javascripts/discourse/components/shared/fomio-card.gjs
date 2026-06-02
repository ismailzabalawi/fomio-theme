import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";

const SURFACE_CLASSES = {
  elevated: "fomio-card",
  flat: "fomio-card fomio-card--flat",
};

export default class FomioCard extends Component {
  get tagName() {
    return this.args.tag ?? (this.args.href ? "a" : "div");
  }

  get className() {
    const classes = [SURFACE_CLASSES[this.args.surface] || SURFACE_CLASSES.elevated];

    if (this.args.interactive) {
      classes.push("fomio-card--interactive");
    }

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
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
    {{else}}
      <div class={{this.className}} ...attributes>
        {{yield}}
      </div>
    {{/if}}
  </template>
}
