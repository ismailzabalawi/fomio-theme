import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioNotificationsSectionMenu from "../../components/fomio-notifications-section-menu";

/**
 * Host outlet: `discourse/.../application.gjs` → `top-notices`.
 * Note: outlet `currentPath` is Ember’s route path (e.g. `user.userNotifications.index`),
 * not a URL — never use it for `/u/...` matching.
 */
export default class FomioNotificationsSectionMenuConnector extends Component {
  @service router;
  @service currentUser;

  get urlPathNoQuery() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get isUserNotificationsPath() {
    const p = this.urlPathNoQuery;
    if (/^\/u\/[^/]+\/notifications(\/|$)/.test(p)) {
      return true;
    }
    if (p === "/notifications" || p.startsWith("/notifications/")) {
      return true;
    }
    const routeName = this.router.currentRouteName || "";
    return routeName.startsWith("userNotifications.");
  }

  get shouldRender() {
    return Boolean(this.currentUser) && this.isUserNotificationsPath;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioNotificationsSectionMenu
        @usernameFallback={{this.currentUser.username}}
      />
    {{/if}}
  </template>
}
