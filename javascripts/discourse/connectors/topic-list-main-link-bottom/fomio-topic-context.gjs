import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioByteCard from "../../components/shared/fomio-byte-card";
import { isFomioActivityM2BytesRoute } from "../../lib/fomio-activity-paths";
import FomioActivityTopicRow from "../../components/fomio-activity-topic-row";

export default class FomioTopicContext extends Component {
  @service router;

  get topic() {
    return this.args.outletArgs.topic;
  }

  get isActivityTopics() {
    return isFomioActivityM2BytesRoute(this.router.currentRouteName);
  }

  <template>
    {{#if this.isActivityTopics}}
      <FomioActivityTopicRow @topic={{this.topic}} />
    {{else}}
      <FomioByteCard @topic={{this.topic}} />
    {{/if}}
  </template>
}
