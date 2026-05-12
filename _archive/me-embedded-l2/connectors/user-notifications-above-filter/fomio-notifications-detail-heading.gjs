import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioOwnedNotifications from "../../components/fomio-owned-notifications";

// Verified outlet: discourse/.../templates/user/notifications-index.gjs
// @name="user-notifications-above-filter" (non-empty list state only).
export default class FomioNotificationsDetailHeading extends Component {
  get title() {
    return i18n(themePrefix("notifications_detail.heading_title"));
  }

  get description() {
    return i18n(themePrefix("notifications_detail.heading_description"));
  }

  <template>
    <div class="fomio-notifications-detail-heading">
      <h2 class="fomio-notifications-detail-heading__title">{{this.title}}</h2>
      <p class="fomio-notifications-detail-heading__description">{{this.description}}</p>
    </div>
    <FomioOwnedNotifications />
  </template>
}
