import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";
import icon from "discourse/helpers/d-icon";
import { listItemClassNames } from "../../lib/fomio-content-classes";

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
    return listItemClassNames(this.args);
  }

  get buttonType() {
    return this.args.type ?? "button";
  }

  get isActive() {
    return this.args.isActive ?? this.args.active;
  }

  get isDisabled() {
    return this.args.isDisabled ?? this.args.disabled;
  }

  get hasStructuredContent() {
    return Boolean(
      this.args.leadingIcon ||
        this.args.title ||
        this.args.subtitle ||
        this.args.meta ||
        this.args.trailingIcon
    );
  }

  <template>
    {{#if (eq this.wrapperTagName "div")}}
      <div class={{this.wrapperClass}}>
        {{#if (eq this.itemTagName "a")}}
          <a
            href={{@href}}
            class={{this.className}}
            aria-current={{if this.isActive "true" @ariaCurrent}}
            aria-disabled={{if this.isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{#if this.hasStructuredContent}}
              {{#if @leadingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @leadingIcon}}</span>
              {{/if}}
              <span class="fomio-list__content">
                <span class="fomio-list__title">{{@title}}</span>
                {{#if @subtitle}}
                  <span class="fomio-list__subtitle">{{@subtitle}}</span>
                {{/if}}
              </span>
              {{#if @meta}}
                <span class="fomio-list__meta">{{@meta}}</span>
              {{/if}}
              {{#if @trailingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @trailingIcon}}</span>
              {{/if}}
            {{else}}
              {{yield}}
            {{/if}}
          </a>
        {{else if (eq this.itemTagName "div")}}
          <div
            class={{this.className}}
            aria-current={{if this.isActive "true" @ariaCurrent}}
            aria-disabled={{if this.isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{#if this.hasStructuredContent}}
              {{#if @leadingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @leadingIcon}}</span>
              {{/if}}
              <span class="fomio-list__content">
                <span class="fomio-list__title">{{@title}}</span>
                {{#if @subtitle}}
                  <span class="fomio-list__subtitle">{{@subtitle}}</span>
                {{/if}}
              </span>
              {{#if @meta}}
                <span class="fomio-list__meta">{{@meta}}</span>
              {{/if}}
              {{#if @trailingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @trailingIcon}}</span>
              {{/if}}
            {{else}}
              {{yield}}
            {{/if}}
          </div>
        {{else}}
          <button
            type={{this.buttonType}}
            class={{this.className}}
            disabled={{this.isDisabled}}
            aria-current={{if this.isActive "true" @ariaCurrent}}
            aria-disabled={{if this.isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{#if this.hasStructuredContent}}
              {{#if @leadingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @leadingIcon}}</span>
              {{/if}}
              <span class="fomio-list__content">
                <span class="fomio-list__title">{{@title}}</span>
                {{#if @subtitle}}
                  <span class="fomio-list__subtitle">{{@subtitle}}</span>
                {{/if}}
              </span>
              {{#if @meta}}
                <span class="fomio-list__meta">{{@meta}}</span>
              {{/if}}
              {{#if @trailingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @trailingIcon}}</span>
              {{/if}}
            {{else}}
              {{yield}}
            {{/if}}
          </button>
        {{/if}}
      </div>
    {{else}}
      <li class={{this.wrapperClass}}>
        {{#if (eq this.itemTagName "a")}}
          <a
            href={{@href}}
            class={{this.className}}
            aria-current={{if this.isActive "true" @ariaCurrent}}
            aria-disabled={{if this.isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{#if this.hasStructuredContent}}
              {{#if @leadingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @leadingIcon}}</span>
              {{/if}}
              <span class="fomio-list__content">
                <span class="fomio-list__title">{{@title}}</span>
                {{#if @subtitle}}
                  <span class="fomio-list__subtitle">{{@subtitle}}</span>
                {{/if}}
              </span>
              {{#if @meta}}
                <span class="fomio-list__meta">{{@meta}}</span>
              {{/if}}
              {{#if @trailingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @trailingIcon}}</span>
              {{/if}}
            {{else}}
              {{yield}}
            {{/if}}
          </a>
        {{else if (eq this.itemTagName "div")}}
          <div
            class={{this.className}}
            aria-current={{if this.isActive "true" @ariaCurrent}}
            aria-disabled={{if this.isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{#if this.hasStructuredContent}}
              {{#if @leadingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @leadingIcon}}</span>
              {{/if}}
              <span class="fomio-list__content">
                <span class="fomio-list__title">{{@title}}</span>
                {{#if @subtitle}}
                  <span class="fomio-list__subtitle">{{@subtitle}}</span>
                {{/if}}
              </span>
              {{#if @meta}}
                <span class="fomio-list__meta">{{@meta}}</span>
              {{/if}}
              {{#if @trailingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @trailingIcon}}</span>
              {{/if}}
            {{else}}
              {{yield}}
            {{/if}}
          </div>
        {{else}}
          <button
            type={{this.buttonType}}
            class={{this.className}}
            disabled={{this.isDisabled}}
            aria-current={{if this.isActive "true" @ariaCurrent}}
            aria-disabled={{if this.isDisabled "true" @ariaDisabled}}
            ...attributes
          >
            {{#if this.hasStructuredContent}}
              {{#if @leadingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @leadingIcon}}</span>
              {{/if}}
              <span class="fomio-list__content">
                <span class="fomio-list__title">{{@title}}</span>
                {{#if @subtitle}}
                  <span class="fomio-list__subtitle">{{@subtitle}}</span>
                {{/if}}
              </span>
              {{#if @meta}}
                <span class="fomio-list__meta">{{@meta}}</span>
              {{/if}}
              {{#if @trailingIcon}}
                <span class="fomio-list__icon" aria-hidden="true">{{icon @trailingIcon}}</span>
              {{/if}}
            {{else}}
              {{yield}}
            {{/if}}
          </button>
        {{/if}}
      </li>
    {{/if}}
  </template>
}
