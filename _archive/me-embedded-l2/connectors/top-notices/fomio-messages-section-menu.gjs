import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioMessagesSectionMenu from "../../components/fomio-messages-section-menu";

/**
 * Host outlet: `application.gjs` → `top-notices`.
 * Never gate on outlet `currentPath` — use `router.currentURL` (URL path), not Ember’s dot path.
 */
export default class FomioMessagesSectionMenuConnector extends Component {
  @service router;
  @service currentUser;

  get urlPathNoQuery() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get isMessagesPath() {
    const p = this.urlPathNoQuery;
    if (/^\/u\/[^/]+\/messages(\/|$)/.test(p)) {
      return true;
    }
    if (/^\/my\/messages(\/|$)/.test(p)) {
      return true;
    }
    const routeName = this.router.currentRouteName || "";
    return routeName.startsWith("userPrivateMessages");
  }

  get shouldRender() {
    return Boolean(this.currentUser) && this.isMessagesPath;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioMessagesSectionMenu />
    {{/if}}
  </template>
}
