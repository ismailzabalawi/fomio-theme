import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioMeFilterChips from "../../components/fomio-me-filter-chips";

/** Verified: `discourse/frontend/discourse/app/templates/user/notifications-index.gjs` — `user-notifications-above-filter`. */
export default class FomioMeNotificationsFilterChipsConnector extends Component {
  @service router;

  get isNotificationsIndex() {
    return this.router.currentRouteName === "userNotifications.index";
  }

  get filters() {
    return [
      { id: "all", labelKey: "me_filter_chips.notifications.all" },
      { id: "conversations", labelKey: "me_filter_chips.notifications.conversations" },
      { id: "reactions", labelKey: "me_filter_chips.notifications.reactions" },
      { id: "system", labelKey: "me_filter_chips.notifications.system" },
    ];
  }

  <template>
    {{#if this.isNotificationsIndex}}
      <FomioMeFilterChips
        @dataAttributeName="data-fomio-me-notifications-filter"
        @groupLabelKey="me_filter_chips.notifications.nav_aria"
        @filters={{this.filters}}
        @initialFilterId="all"
      />
    {{/if}}
  </template>
}
