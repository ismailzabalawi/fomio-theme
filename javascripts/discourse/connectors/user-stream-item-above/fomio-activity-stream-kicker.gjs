// Editorial action-type kicker for the profile Activity feed.
// Renders through Discourse core's `user-stream-item-above` outlet
// (user-stream.gjs passes `@outletArgs={{lazyHash item=post}}`), so the
// stream item itself stays core-rendered and PostList's DLoadMore
// infinite scrolling is untouched. Only renders on user activity routes.
import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// Numeric ids from core's UserActionTypes (models/user-action.js).
const KICKER_KEYS = {
  1: "like",
  2: "like",
  4: "byte",
  5: "reply",
  6: "reply",
  7: "mention",
  9: "quote",
  11: "edit",
  17: "link",
};

export default class FomioActivityStreamKicker extends Component {
  @service router;

  get label() {
    if (!this.router.currentRouteName?.startsWith("userActivity")) {
      return null;
    }

    const item = this.args.outletArgs?.item;
    if (!item) {
      return null;
    }

    const key = item.draftType ? "draft" : KICKER_KEYS[item.action_type];
    if (!key) {
      return null;
    }

    return i18n(themePrefix(`activity_stream.kicker.${key}`));
  }

  <template>
    {{#if this.label}}
      <span class="fomio-activity-stream-kicker">{{this.label}}</span>
    {{/if}}
  </template>
}
