import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioPhIcon from "../../components/shared/fomio-ph-icon";
import { isFomioActivityM2BytesRoute } from "../../lib/fomio-activity-paths";
import {
  bindBytesTypeLabelToMeta,
  iconForActionKey,
} from "../../lib/fomio-activity-timeline";

const BYTES_ACTION_KEY = "created_byte";

export default class FomioActivityBytesTimelineRow extends Component {
  @service router;

  get shouldRender() {
    return isFomioActivityM2BytesRoute(this.router.currentRouteName);
  }

  get label() {
    return i18n(themePrefix(`activity_screen.actions.${BYTES_ACTION_KEY}`));
  }

  get icon() {
    return iconForActionKey(BYTES_ACTION_KEY);
  }

  @action
  bindBytesRow(element) {
    if (typeof window === "undefined") {
      bindBytesTypeLabelToMeta(element);
      return;
    }

    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        bindBytesTypeLabelToMeta(element);
      });
    });
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="fomio-activity-bytes-row-prefix"
        {{didInsert this.bindBytesRow}}
      >
        <div
          class="fomio-activity-timeline-leading fomio-activity-bytes-leading"
          data-fomio-activity-action={{BYTES_ACTION_KEY}}
        >
          <span class="fomio-activity-timeline-leading__icon" aria-hidden="true">
            <FomioPhIcon @name={{this.icon}} @size={{15}} />
          </span>
        </div>

        <span class="fomio-activity-timeline-type-label">{{this.label}}</span>
      </div>
    {{/if}}
  </template>
}
