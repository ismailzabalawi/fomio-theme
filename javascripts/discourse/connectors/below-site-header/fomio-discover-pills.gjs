import Component from "@glimmer/component";

export default class FomioDiscoverPills extends Component {
  get shouldRender() {
    return false;
  }

  <template>
    {{#if this.shouldRender}}{{/if}}
  </template>
}
