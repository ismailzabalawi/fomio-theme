import Component from "@glimmer/component";
import FomioActivityProfileStrip from "../../components/fomio-activity-profile-strip";

export default class FomioUserProfileHeaderAbove extends Component {
  <template>
    <FomioActivityProfileStrip @outletArgs={{@outletArgs}} />
  </template>
}
