import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// Keep in sync with fomio-sidebar.gjs and fomio-layout.gjs.
// Discourse themes cannot share modules across files.
const AUTH_PATHS = [
  "/login",
  "/signup",
  "/session/",
  "/user-api-key",
  "/password-reset",
  "/u/activate-account",
  "/u/account-created",
  "/invites",
  "/u/confirm",
  "/auth/",
];

function isAuthPath(url) {
  return AUTH_PATHS.some((p) => url.startsWith(p));
}

export default class FomioBottomBar extends Component {
  @service router;

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return !isAuthPath(this.currentPath);
  }

  get openMenuLabel() {
    return i18n(themePrefix("sidebar.open_menu"));
  }

  @action
  toggleSidebar() {
    document.body.classList.toggle("fomio-mobile-sidebar-open");
  }

  <template>
    {{#if this.shouldRender}}
      <button
        type="button"
        class="fomio-mobile-menu-btn"
        aria-label={{this.openMenuLabel}}
        aria-controls="fomio-sidebar-nav"
        {{on "click" this.toggleSidebar}}
      >
        {{icon "bars"}}
      </button>
    {{/if}}
  </template>
}
