import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";

export default class FomioListItem extends Component {
  get wrapperTagName() {
    return this.args.wrapperTag ?? "li";
  }

  get itemTagName() {
    if (this.args.tag) {
      return this.args.tag;
    }

    if (this.args.href) {
      return "a";
    }

    return "button";
  }

  get wrapperClass() {
    return this.args.wrapperClass ?? null;
  }

  get className() {
    const classes = ["fomio-list__item"];

    if (this.args.isActive) {
      classes.push("fomio-list__item--active");
    }

    if (this.args.isDanger) {
      classes.push("fomio-list__item--danger");
    }

    if (this.args.isDisabled) {
      classes.push("fomio-list__item--disabled");
    }

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
  }

  get buttonType() {
    return this.args.type ?? "button";
  }

  <template>
    {{#if (eq this.wrapperTagName "div")}}
      <div class={{this.wrapperClass}}>
        {{#if (eq this.itemTagName "a")}}
          <a
            href={{@href}}
            class={{this.className}}
            aria-current={{if @isActive "true" @ariaCurrent}}
            aria-disabled={{if @isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{yield}}
          </a>
        {{else if (eq this.itemTagName "div")}}
          <div
            class={{this.className}}
            aria-current={{if @isActive "true" @ariaCurrent}}
            aria-disabled={{if @isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{yield}}
          </div>
        {{else}}
          <button
            type={{this.buttonType}}
            class={{this.className}}
            disabled={{@isDisabled}}
            aria-current={{if @isActive "true" @ariaCurrent}}
            aria-disabled={{if @isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{yield}}
          </button>
        {{/if}}
      </div>
    {{else}}
      <li class={{this.wrapperClass}}>
        {{#if (eq this.itemTagName "a")}}
          <a
            href={{@href}}
            class={{this.className}}
            aria-current={{if @isActive "true" @ariaCurrent}}
            aria-disabled={{if @isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{yield}}
          </a>
        {{else if (eq this.itemTagName "div")}}
          <div
            class={{this.className}}
            aria-current={{if @isActive "true" @ariaCurrent}}
            aria-disabled={{if @isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{yield}}
          </div>
        {{else}}
          <button
            type={{this.buttonType}}
            class={{this.className}}
            disabled={{@isDisabled}}
            aria-current={{if @isActive "true" @ariaCurrent}}
            aria-disabled={{if @isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{yield}}
          </button>
        {{/if}}
      </li>
    {{/if}}
  </template>
}
