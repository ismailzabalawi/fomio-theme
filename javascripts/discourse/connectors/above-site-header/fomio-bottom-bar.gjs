import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
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

const WEB_LOGIN_URL = "/login?fomio_web=1";

function isAuthPath(url) {
  return AUTH_PATHS.some((p) => url.startsWith(p));
}

export default class FomioBottomBar extends Component {
  @service router;
  @service currentUser;
  @service composer;

  @tracked isHidden = false;
  #lastScrollY = 0;
  #scrollHandler = null;

  constructor(owner, args) {
    super(owner, args);
    this.#scrollHandler = () => {
      const y = window.scrollY;
      if (y > this.#lastScrollY && y > 50) {
        this.isHidden = true;
      } else {
        this.isHidden = false;
      }
      this.#lastScrollY = y;
    };
    window.addEventListener("scroll", this.#scrollHandler, { passive: true });
  }

  willDestroy() {
    super.willDestroy();
    window.removeEventListener("scroll", this.#scrollHandler);
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return !isAuthPath(this.currentPath);
  }

  get isLatestActive() {
    const p = this.currentPath;
    return p === "/" || p.startsWith("/latest");
  }

  get isHotActive() {
    return this.currentPath.startsWith("/hot");
  }

  get isHubsActive() {
    const p = this.currentPath;
    return p === "/categories" || p.startsWith("/c/");
  }

  get isProfileActive() {
    return this.currentPath.startsWith("/u/");
  }

  get profileUrl() {
    return this.currentUser
      ? `/u/${this.currentUser.username}/summary`
      : WEB_LOGIN_URL;
  }

  get latestLabel()  { return i18n(themePrefix("bottom_bar.latest")); }
  get hotLabel()     { return i18n(themePrefix("bottom_bar.hot")); }
  get newByteLabel() { return i18n(themePrefix("bottom_bar.new_byte")); }
  get hubsLabel()    { return i18n(themePrefix("bottom_bar.hubs")); }
  get profileLabel() { return i18n(themePrefix("bottom_bar.profile")); }

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
      <nav
        class="fomio-bottom-bar {{if this.isHidden 'fomio-bottom-bar--hidden'}}"
        aria-label="Main navigation"
      >
        <a
          href="/latest"
          class="fomio-bottom-bar__item {{if this.isLatestActive 'is-active'}}"
          aria-current={{if this.isLatestActive "page"}}
          title={{this.latestLabel}}
        >
          {{icon "clock"}}
          <span class="fomio-bottom-bar__label">{{this.latestLabel}}</span>
        </a>

        <a
          href="/hot"
          class="fomio-bottom-bar__item {{if this.isHotActive 'is-active'}}"
          aria-current={{if this.isHotActive "page"}}
          title={{this.hotLabel}}
        >
          {{icon "fire"}}
          <span class="fomio-bottom-bar__label">{{this.hotLabel}}</span>
        </a>

        <button
          type="button"
          class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
          title={{this.newByteLabel}}
          {{on "click" this.openNewByte}}
        >
          {{icon "pen-to-square"}}
          <span class="fomio-bottom-bar__label">{{this.newByteLabel}}</span>
        </button>

        <a
          href="/categories"
          class="fomio-bottom-bar__item {{if this.isHubsActive 'is-active'}}"
          aria-current={{if this.isHubsActive "page"}}
          title={{this.hubsLabel}}
        >
          {{icon "compass"}}
          <span class="fomio-bottom-bar__label">{{this.hubsLabel}}</span>
        </a>

        <a
          href={{this.profileUrl}}
          class="fomio-bottom-bar__item {{if this.isProfileActive 'is-active'}}"
          aria-current={{if this.isProfileActive "page"}}
          title={{this.profileLabel}}
        >
          {{icon "user"}}
          <span class="fomio-bottom-bar__label">{{this.profileLabel}}</span>
        </a>
      </nav>
    {{/if}}
  </template>
}
