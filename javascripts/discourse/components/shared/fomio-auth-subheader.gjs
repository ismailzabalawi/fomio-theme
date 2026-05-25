import Component from "@glimmer/component";

export default class FomioAuthSubheader extends Component {
  get stackClass() {
    return this.args.stackClass ?? "";
  }

  get eyebrowClass() {
    return this.args.eyebrowClass ?? "";
  }

  get bodyClass() {
    return this.args.bodyClass ?? "";
  }

  <template>
    <div class={{this.stackClass}}>
      {{#if @intentMessage}}
        <p class="fomio-auth-intent">{{@intentMessage}}</p>
      {{/if}}
      {{#if @eyebrowText}}
        <p class={{this.eyebrowClass}}>{{@eyebrowText}}</p>
      {{/if}}
      {{#if @bodyText}}
        <p class={{this.bodyClass}}>{{@bodyText}}</p>
      {{/if}}
    </div>
  </template>
}
