import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioOwnedActivity from "../../components/fomio-owned-activity";

export default class FomioOwnedActivityConnector extends Component {
  @service router;
  
  get isActivityRoute() {
    return this.router.currentRouteName?.startsWith("userActivity");
  }

  <template>
    {{#if this.isActivityRoute}}
      <FomioOwnedActivity />
    {{/if}}
  </template>
}
