import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";
import {
  bookmarksPathForUser,
  isAuthPath,
  isDiscoverPath,
  isHomeFeedPath,
  isMePath,
  isSavedPath,
  profileSummaryPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import { armMeHubLandingForNextSummaryVisit } from "../../lib/fomio-me-hub-landing";

const WEB_LOGIN_URL = "/login?fomio_web=1";

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

  get isHomeActive() {
    return isHomeFeedPath(this.currentPath);
  }

  get isDiscoverActive() {
    return isDiscoverPath(this.currentPath);
  }

  get isSavedActive() {
    return isSavedPath(this.currentPath);
  }

  get isMeActive() {
    return isMePath(this.currentPath);
  }

  get bookmarksUrl() {
    return bookmarksPathForUser(this.currentUser);
  }

  get profileUrl() {
    return profileSummaryPathForUser(this.currentUser) ?? WEB_LOGIN_URL;
  }

  get navAriaLabel() {
    return i18n(themePrefix("mobile_nav.aria_nav"));
  }

  get homeLabel() {
    return i18n(themePrefix("mobile_nav.home"));
  }

  get discoverLabel() {
    return i18n(themePrefix("mobile_nav.discover"));
  }

  get createLabel() {
    return i18n(themePrefix("mobile_nav.create"));
  }

  get savedLabel() {
    return i18n(themePrefix("mobile_nav.saved"));
  }

  get meLabel() {
    return i18n(themePrefix("mobile_nav.me"));
  }

  @action
  openNewByte() {
    if (this.currentUser) {
      try {
        this.composer.openNewTopic();
      } catch (e) {
        console.warn("[Fomio] composer.openNewTopic failed from bottom bar", e);
      }
    } else {
      redirectToLoginWithIntent("create_byte", this.currentPath);
    }
  }

  @action
  goToSaved(e) {
    e?.preventDefault();
    if (this.currentUser) {
      const url = bookmarksPathForUser(this.currentUser);
      if (url) {
        window.location.assign(url);
      }
    } else {
      redirectToLoginWithIntent("view_saved", this.currentPath);
    }
  }

  @action
  goToMe(e) {
    e?.preventDefault();
    if (this.currentUser) {
      const url = profileSummaryPathForUser(this.currentUser);
      if (url) {
        armMeHubLandingForNextSummaryVisit();
        window.location.assign(url);
      }
    } else {
      redirectToLoginWithIntent("view_profile", this.currentPath);
    }
  }

  @action
  armMeHubLanding(e) {
    if (
      e &&
      (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey || e.button !== 0)
    ) {
      return;
    }
    armMeHubLandingForNextSummaryVisit();
  }

  <template>
    {{#if this.shouldRender}}
      <nav
        class="fomio-bottom-bar {{if this.isHidden 'fomio-bottom-bar--hidden'}}"
        aria-label={{this.navAriaLabel}}
      >
        <a
          href="/latest"
          class="fomio-bottom-bar__item {{if this.isHomeActive 'is-active'}}"
          aria-current={{if this.isHomeActive "page"}}
          title={{this.homeLabel}}
        >
          {{icon "clock"}}
          <span class="fomio-bottom-bar__label">{{this.homeLabel}}</span>
        </a>

        <a
          href="/categories"
          class="fomio-bottom-bar__item {{if this.isDiscoverActive 'is-active'}}"
          aria-current={{if this.isDiscoverActive "page"}}
          title={{this.discoverLabel}}
        >
          {{icon "compass"}}
          <span class="fomio-bottom-bar__label">{{this.discoverLabel}}</span>
        </a>

        <button
          type="button"
          class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
          aria-label={{this.createLabel}}
          title={{this.createLabel}}
          {{on "click" this.openNewByte}}
        >
          {{icon "pen-to-square"}}
          <span class="fomio-bottom-bar__label">{{this.createLabel}}</span>
        </button>

        {{#if this.currentUser}}
          <a
            href={{this.bookmarksUrl}}
            class="fomio-bottom-bar__item {{if this.isSavedActive 'is-active'}}"
            aria-current={{if this.isSavedActive "page"}}
            title={{this.savedLabel}}
          >
            {{icon "bookmark"}}
            <span class="fomio-bottom-bar__label">{{this.savedLabel}}</span>
          </a>
        {{else}}
          <button
            type="button"
            class="fomio-bottom-bar__item {{if this.isSavedActive 'is-active'}}"
            title={{this.savedLabel}}
            {{on "click" this.goToSaved}}
          >
            {{icon "bookmark"}}
            <span class="fomio-bottom-bar__label">{{this.savedLabel}}</span>
          </button>
        {{/if}}

        {{#if this.currentUser}}
          <a
            href={{this.profileUrl}}
            class="fomio-bottom-bar__item {{if this.isMeActive 'is-active'}}"
            aria-current={{if this.isMeActive "page"}}
            title={{this.meLabel}}
            {{on "click" this.armMeHubLanding}}
          >
            {{icon "user"}}
            <span class="fomio-bottom-bar__label">{{this.meLabel}}</span>
          </a>
        {{else}}
          <button
            type="button"
            class="fomio-bottom-bar__item {{if this.isMeActive 'is-active'}}"
            title={{this.meLabel}}
            {{on "click" this.goToMe}}
          >
            {{icon "user"}}
            <span class="fomio-bottom-bar__label">{{this.meLabel}}</span>
          </button>
        {{/if}}
      </nav>
    {{/if}}
  </template>
}
