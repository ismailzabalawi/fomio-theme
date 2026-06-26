import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioByteCard from "../../components/shared/fomio-byte-card";
import { isFomioActivityM2BytesRoute } from "../../lib/fomio-activity-paths";

export default class FomioTopicContext extends Component {
  @service router;

  get topic() {
    return this.args.outletArgs.topic;
  }

  get shouldRender() {
    return !isFomioActivityM2BytesRoute(this.router.currentRouteName);
  }

  <template>
    {{#if this.shouldRender}}
      <FomioByteCard @topic={{this.topic}} />
    {{/if}}
  </template>
}
