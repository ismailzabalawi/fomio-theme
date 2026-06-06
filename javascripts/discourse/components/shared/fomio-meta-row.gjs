import Component from "@glimmer/component";
import { metaRowClassNames } from "../../lib/fomio-content-classes";

export default class FomioMetaRow extends Component {
  get className() {
    return metaRowClassNames(this.args);
  }

  <template>
    <div class={{this.className}} ...attributes>
      {{yield}}
    </div>
  </template>
}
