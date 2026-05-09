import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioActivitySectionMenu from "../../components/fomio-activity-section-menu";

/**
 * Host outlet: `discourse/.../application.gjs` → `top-notices`.
 * Gate on `router.currentURL` (not outlet `currentPath`).
 */
export default class FomioActivitySectionMenuConnector extends Component {
  @service router;
  @service currentUser;

  get urlPathNoQuery() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get isUserActivityPath() {
    const p = this.urlPathNoQuery;
    if (/^\/u\/[^/]+\/activity(\/|$)/.test(p)) {
      return true;
    }
    const routeName = this.router.currentRouteName || "";
    return routeName.startsWith("userActivity.");
  }

  get shouldRender() {
    return Boolean(this.currentUser) && this.isUserActivityPath;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioActivitySectionMenu />
    {{/if}}
  </template>
}
