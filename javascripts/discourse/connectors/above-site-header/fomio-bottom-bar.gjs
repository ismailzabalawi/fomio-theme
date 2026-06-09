import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioPhIcon from "../../components/shared/fomio-ph-icon";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";
import {
  isDiscoverPath,
  isFomioShellPath,
  isHomeFeedPath,
  isMePath,
  isOwnNotificationsPath,
  meHubPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import { subscribeMessagesState } from "../../lib/fomio-messages-state";
import { fomioCurrentPath } from "../../lib/fomio-router-pathname";
import {
  closeFomioNotificationsMenu,
  FOMIO_NOTIFICATIONS_MENU_STATE_EVENT,
  openFomioNotificationsMenu,
} from "../../lib/fomio-notifications-menu";

const WEB_LOGIN_URL = "/login?fomio_web=1";
const HIDE_START_Y = 120;
const HIDE_DELTA_Y = 18;
const SHOW_DELTA_Y = 10;
const MIN_SCROLLABLE_HEIGHT = 180;

export default class FomioBottomBar extends Component {
  @service router;
  @service currentUser;
  @service composer;
  @service interfaceColor;

  @tracked isHidden = false;
  @tracked notificationsMenuOpen = false;
  @tracked messagesFilter = "latest";
  @tracked isDarkModeActive = false;
  #lastScrollY = 0;
  #scrollHandler = null;
  #notificationsMenuStateHandler = null;
  #unsubscribeMessages = null;

  constructor(owner, args) {
    super(owner, args);
    this.#updateDarkModeState();
    this.#scrollHandler = () => {
      const y = window.scrollY;
      const deltaY = y - this.#lastScrollY;
      const scrollableHeight =
        document.documentElement.scrollHeight - window.innerHeight;

      if (!this.shouldAutoHide || scrollableHeight < MIN_SCROLLABLE_HEIGHT) {
        this.isHidden = false;
      } else if (y <= HIDE_START_Y) {
        this.isHidden = false;
      } else if (deltaY >= HIDE_DELTA_Y) {
        this.isHidden = true;
      } else if (deltaY <= -SHOW_DELTA_Y) {
        this.isHidden = false;
      }

      this.#lastScrollY = y;
    };
    window.addEventListener("scroll", this.#scrollHandler, { passive: true });
    this.#notificationsMenuStateHandler = (event) => {
      this.notificationsMenuOpen = Boolean(event?.detail?.open);
    };
    window.addEventListener(
      FOMIO_NOTIFICATIONS_MENU_STATE_EVENT,
      this.#notificationsMenuStateHandler
    );
    this.#unsubscribeMessages = subscribeMessagesState((s) => {
      this.messagesFilter = s.filter;
    });
    window.addEventListener("fomio:dark-mode:changed", () => {
      this.#updateDarkModeState();
    });
  }

  willDestroy() {
    super.willDestroy();
    window.removeEventListener("scroll", this.#scrollHandler);
    window.removeEventListener(
      FOMIO_NOTIFICATIONS_MENU_STATE_EVENT,
      this.#notificationsMenuStateHandler
    );
    window.removeEventListener("fomio:dark-mode:changed", () => {
      this.#updateDarkModeState();
    });
    this.#unsubscribeMessages?.();
  }

  #updateDarkModeState() {
    if (typeof document === "undefined") {
      return;
    }
    this.isDarkModeActive = document.documentElement.classList.contains("fomio-color-dark");
  }

  get currentPath() {
    return fomioCurrentPath(this.router.currentURL || "");
  }

  get shouldRender() {
    return isFomioShellPath(this.currentPath);
  }

  get isHomeActive() {
    return isHomeFeedPath(this.currentPath);
  }

  get isDiscoverActive() {
    return isDiscoverPath(this.currentPath);
  }

  get isNotificationsActive() {
    return (
      isOwnNotificationsPath(this.currentPath, this.currentUser) ||
      this.notificationsMenuOpen
    );
  }

  get isMeActive() {
    return isMePath(this.currentPath, this.currentUser);
  }

  get shouldAutoHide() {
    return !this.isMeActive;
  }

  get profileUrl() {
    return meHubPathForUser(this.currentUser) ?? WEB_LOGIN_URL;
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

  get notificationsLabel() {
    return i18n(themePrefix("mobile_nav.notifications"));
  }

  get meLabel() {
    return i18n(themePrefix("mobile_nav.me"));
  }

  get toggleDarkModeLabel() {
    return i18n(themePrefix("mobile_nav.toggle_dark_mode"));
  }

  @action
  toggleColorScheme() {
    // Discourse's interfaceColor service toggles between light and dark modes
    // by updating the user's color scheme preference
    this.interfaceColor?.toggleDarkMode?.();
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

  get notificationsBadge() {
    const count = this.currentUser?.all_unread_notifications_count;
    if (!count || count <= 0) {
      return null;
    }

    return count > 99 ? "99+" : String(count);
  }

  get messagesBadge() {
    const count = this.currentUser?.unread_private_messages;
    if (!count || count <= 0) {
      return null;
    }

    return count > 99 ? "99+" : String(count);
  }

  @action
  openNotifications(e) {
    e?.preventDefault();
    if (this.currentUser) {
      if (this.notificationsMenuOpen) {
        closeFomioNotificationsMenu();
      } else {
        openFomioNotificationsMenu("mobile");
      }
    } else {
      redirectToLoginWithIntent("view_profile", this.currentPath);
    }
  }

  @action
  goToMe(e) {
    e?.preventDefault();
    if (this.currentUser) {
      const url = meHubPathForUser(this.currentUser);
      if (url) {
        window.location.assign(url);
      }
    } else {
      redirectToLoginWithIntent("view_profile", this.currentPath);
    }
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
          <span class="fomio-bottom-bar__icon">{{icon "clock"}}</span>
          <span class="fomio-bottom-bar__label">{{this.homeLabel}}</span>
        </a>

        <a
          href="/categories"
          class="fomio-bottom-bar__item {{if this.isDiscoverActive 'is-active'}}"
          aria-current={{if this.isDiscoverActive "page"}}
          title={{this.discoverLabel}}
        >
          <span class="fomio-bottom-bar__icon">{{icon "compass"}}</span>
          <span class="fomio-bottom-bar__label">{{this.discoverLabel}}</span>
        </a>

        <button
          type="button"
          class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
          aria-label={{this.createLabel}}
          title={{this.createLabel}}
          {{on "click" this.openNewByte}}
        >
          <span class="fomio-bottom-bar__icon">{{icon "pen-to-square"}}</span>
          <span class="fomio-bottom-bar__label">{{this.createLabel}}</span>
        </button>

        {{#if this.currentUser}}
          <button
            type="button"
            class="fomio-bottom-bar__item {{if this.isNotificationsActive 'is-active'}}"
            aria-current={{if this.isNotificationsActive "page"}}
            title={{this.notificationsLabel}}
            {{on "click" this.openNotifications}}
          >
            <span class="fomio-bottom-bar__icon">
              {{icon "bell"}}
              {{#if this.notificationsBadge}}
                <span class="fomio-bottom-bar__badge">{{this.notificationsBadge}}</span>
              {{/if}}
            </span>
            <span class="fomio-bottom-bar__label">{{this.notificationsLabel}}</span>
          </button>
        {{else}}
          <button
            type="button"
            class="fomio-bottom-bar__item {{if this.isNotificationsActive 'is-active'}}"
            title={{this.notificationsLabel}}
            {{on "click" this.openNotifications}}
          >
            <span class="fomio-bottom-bar__icon">{{icon "bell"}}</span>
            <span class="fomio-bottom-bar__label">{{this.notificationsLabel}}</span>
          </button>
        {{/if}}

        {{#if this.currentUser}}
          <a
            href={{this.profileUrl}}
            class="fomio-bottom-bar__item {{if this.isMeActive 'is-active'}}"
            aria-current={{if this.isMeActive "page"}}
            title={{this.meLabel}}
          >
            <span class="fomio-bottom-bar__icon">
              {{icon "user"}}
              {{#if this.messagesBadge}}
                <span class="fomio-bottom-bar__badge">{{this.messagesBadge}}</span>
              {{/if}}
            </span>
            <span class="fomio-bottom-bar__label">{{this.meLabel}}</span>
          </a>
        {{else}}
          <button
            type="button"
            class="fomio-bottom-bar__item {{if this.isMeActive 'is-active'}}"
            title={{this.meLabel}}
            {{on "click" this.goToMe}}
          >
            <span class="fomio-bottom-bar__icon">{{icon "user"}}</span>
            <span class="fomio-bottom-bar__label">{{this.meLabel}}</span>
          </button>
        {{/if}}

        <button
          type="button"
          class="fomio-bottom-bar__color-toggle"
          title={{this.toggleDarkModeLabel}}
          aria-label={{this.toggleDarkModeLabel}}
          {{on "click" this.toggleColorScheme}}
        >
          <span class="fomio-bottom-bar__icon">
            {{#if this.isDarkModeActive}}
              <FomioPhIcon @name="sun" @size="20" />
            {{else}}
              <FomioPhIcon @name="moon" @size="20" />
            {{/if}}
          </span>
        </button>
      </nav>
    {{/if}}
  </template>
}
