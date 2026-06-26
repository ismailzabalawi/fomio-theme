import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioPhIcon from "../../components/shared/fomio-ph-icon";
import { isFomioActivityM1TimelineRoute } from "../../lib/fomio-activity-paths";
import {
  actionKeyFromItem,
  bindTimelineTypeLabelToMetadata,
  iconForActionKey,
} from "../../lib/fomio-activity-timeline";

export default class FomioActivityTimelineRow extends Component {
  @service router;

  get item() {
    return this.args.outletArgs?.item;
  }

  get actionKey() {
    return actionKeyFromItem(this.item);
  }

  get shouldRender() {
    return (
      isFomioActivityM1TimelineRoute(this.router.currentRouteName) &&
      Boolean(this.actionKey)
    );
  }

  get label() {
    if (!this.actionKey) {
      return null;
    }

    return i18n(themePrefix(`activity_screen.actions.${this.actionKey}`));
  }

  get icon() {
    return iconForActionKey(this.actionKey);
  }

  @action
  bindTimelineRow(element) {
    bindTimelineTypeLabelToMetadata(element);
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="fomio-activity-timeline-row-prefix"
        {{didInsert this.bindTimelineRow}}
      >
        <div
          class="fomio-activity-timeline-leading"
          data-fomio-activity-action={{this.actionKey}}
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
