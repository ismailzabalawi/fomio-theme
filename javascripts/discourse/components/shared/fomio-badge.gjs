import Component from "@glimmer/component";
import { badgeClassNames } from "../../lib/fomio-content-classes";

export default class FomioBadge extends Component {
  get className() {
    return badgeClassNames(this.args);
  }

  <template>
    <span class={{this.className}} ...attributes>
      {{yield}}
    </span>
  </template>
}
