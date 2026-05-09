import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioPreferencesSectionMenu from "../../components/fomio-preferences-section-menu";

/**
 * Host outlet: `discourse/.../application.gjs` → `top-notices`.
 * Gate on `router.currentURL` (e.g. `/my/preferences/...`), not outlet `currentPath`.
 */
export default class FomioPreferencesSectionMenuConnector extends Component {
  @service router;
  @service currentUser;

  get urlPathNoQuery() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get isPreferencesPath() {
    const p = this.urlPathNoQuery;
    if (p === "/my/preferences" || p.startsWith("/my/preferences/")) {
      return true;
    }
    const routeName = this.router.currentRouteName || "";
    return routeName.startsWith("preferences.");
  }

  get shouldRender() {
    return Boolean(this.currentUser) && this.isPreferencesPath;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioPreferencesSectionMenu />
    {{/if}}
  </template>
}
