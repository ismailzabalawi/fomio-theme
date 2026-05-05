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

const HOME_URL_PREFIXES = ["/latest", "/new", "/top", "/unread"];
const WEB_LOGIN_URL = "/login?fomio_web=1";

export default class FomioBottomBar extends Component {
  @service router;
  @service currentUser;
  @service composer;

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return !isAuthPath(this.currentPath);
  }

  get isHomeActive() {
    const p = this.currentPath;
    return p === "/" || HOME_URL_PREFIXES.some((prefix) => p.startsWith(prefix));
  }

  get isHubsActive() {
    const p = this.currentPath;
    return p === "/categories" || p.startsWith("/c/");
  }

  get isProfileActive() {
    const p = this.currentPath;
    return (
      p.startsWith("/u/") &&
      !p.includes("/bookmarks") &&
      !p.includes("/notifications")
    );
  }

  get profileUrl() {
    return this.currentUser
      ? `/u/${this.currentUser.username}/summary`
      : WEB_LOGIN_URL;
  }

  get homeLabel() { return i18n(themePrefix("bottom_bar.home")); }
  get hubsLabel() { return i18n(themePrefix("bottom_bar.hubs")); }
  get createLabel() { return i18n(themePrefix("bottom_bar.create")); }
  get profileLabel() {
    return this.currentUser
      ? i18n(themePrefix("bottom_bar.profile"))
      : i18n(themePrefix("bottom_bar.sign_in"));
  }

  @action
  openNewByte() {
    if (this.currentUser) {
      this.composer.openNewTopic();
    } else {
      window.location.href = WEB_LOGIN_URL;
    }
  }

  <template>
    {{#if this.shouldRender}}
      <nav class="fomio-bottom-bar" aria-label="Fomio navigation">

        <a
          href="/latest"
          class="fomio-bottom-bar__item {{if this.isHomeActive 'is-active'}}"
          aria-current={{if this.isHomeActive "page"}}
        >
          <span class="fomio-bottom-bar__icon">{{icon "house"}}</span>
          <span class="fomio-bottom-bar__label">{{this.homeLabel}}</span>
        </a>

        <a
          href="/categories"
          class="fomio-bottom-bar__item {{if this.isHubsActive 'is-active'}}"
          aria-current={{if this.isHubsActive "page"}}
        >
          <span class="fomio-bottom-bar__icon">{{icon "compass"}}</span>
          <span class="fomio-bottom-bar__label">{{this.hubsLabel}}</span>
        </a>

        <button
          type="button"
          class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
          {{on "click" this.openNewByte}}
        >
          <span class="fomio-bottom-bar__icon">{{icon "pen-to-square"}}</span>
          <span class="fomio-bottom-bar__label">{{this.createLabel}}</span>
        </button>

        <a
          href={{this.profileUrl}}
          class="fomio-bottom-bar__item {{if this.isProfileActive 'is-active'}}"
          aria-current={{if this.isProfileActive "page"}}
        >
          <span class="fomio-bottom-bar__icon">{{icon "user"}}</span>
          <span class="fomio-bottom-bar__label">{{this.profileLabel}}</span>
        </a>

      </nav>
    {{/if}}
  </template>
}
