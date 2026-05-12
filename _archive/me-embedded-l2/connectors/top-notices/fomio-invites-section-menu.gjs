import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioInvitesSectionMenu from "../../components/fomio-invites-section-menu";

/**
 * Host outlet: `discourse/.../application.gjs` → `top-notices`.
 * Gate on `router.currentURL` for `/u/.../invited`, not outlet `currentPath`.
 */
export default class FomioInvitesSectionMenuConnector extends Component {
  @service router;
  @service currentUser;

  get urlPathNoQuery() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get isUserInvitedPath() {
    const p = this.urlPathNoQuery;
    if (/^\/u\/[^/]+\/invited(\/|$)/.test(p)) {
      return true;
    }
    const routeName = this.router.currentRouteName || "";
    return routeName.startsWith("userInvited");
  }

  get shouldRender() {
    return Boolean(this.currentUser) && this.isUserInvitedPath;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioInvitesSectionMenu />
    {{/if}}
  </template>
}
