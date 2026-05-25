import Component from "@glimmer/component";
import FomioByteCard from "../../components/shared/fomio-byte-card";

export default class FomioTopicContext extends Component {
  get topic() {
    return this.args.outletArgs.topic;
  }

  <template>
    <FomioByteCard @topic={{this.topic}} />
  </template>
}
