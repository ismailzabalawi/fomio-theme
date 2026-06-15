import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioList from "./fomio-list";
import FomioListItem from "./fomio-list-item";
import FomioButton from "./fomio-button";
import {
  activityPathForUser,
  badgesPathForUser,
  invitedPathForUser,
  messagesPathForUser,
  notificationsPathForUser,
  profileSummaryPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import {
  FOMIO_USER_MENU_CLASS,
  FOMIO_USER_MENU_CLOSE_EVENT,
  FOMIO_USER_MENU_OPEN_EVENT,
  publishFomioUserMenuState,
} from "../../lib/fomio-user-menu";

function normalizePath(path) {
  return path?.split("?")[0]?.replace(/\/+$/, "") || "/";
}

function matchesPath(currentPath, href) {
  const path = normalizePath(currentPath).toLowerCase();
  const target = normalizePath(href).toLowerCase();
  return path === target || path.startsWith(`${target}/`);
}

export default class FomioUserMenu extends Component {
  DESKTOP_GAP = 12;
  DESKTOP_MARGIN = 16;
  DESKTOP_WIDTH = 320;
  DESKTOP_MAX_HEIGHT = 620;

  @service currentUser;
  @service router;
  @service siteSettings;

  @tracked isOpen = false;
  @tracked source = "desktop";
  @tracked anchorRect = null;
  @tracked measuredHeight = 0;

  constructor(owner, args) {
    super(owner, args);

    this._handleOpen = (event) => {
      if (!this.currentUser) {
        return;
      }

      this.source = event?.detail?.source === "mobile" ? "mobile" : "desktop";
      this.anchorRect = event?.detail?.anchorRect ?? null;
      this.isOpen = true;
      document.body?.classList.add(FOMIO_USER_MENU_CLASS);
      publishFomioUserMenuState(true, this.source);
    };

    this._handleClose = () => this.close();
    this._onRouteDidChange = () => this.close();

    if (typeof window !== "undefined") {
      window.addEventListener(FOMIO_USER_MENU_OPEN_EVENT, this._handleOpen);
      window.addEventListener(FOMIO_USER_MENU_CLOSE_EVENT, this._handleClose);
    }

    this.router.on("routeDidChange", this._onRouteDidChange);
  }

  willDestroy() {
    super.willDestroy(...arguments);

    if (typeof window !== "undefined") {
      window.removeEventListener(FOMIO_USER_MENU_OPEN_EVENT, this._handleOpen);
      window.removeEventListener(
        FOMIO_USER_MENU_CLOSE_EVENT,
        this._handleClose
      );
    }

    this.router.off("routeDidChange", this._onRouteDidChange);
    this._panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_USER_MENU_CLASS);
    publishFomioUserMenuState(false, this.source);
  }

  get shouldRender() {
    return Boolean(this.currentUser && this.isOpen);
  }

  get panelClass() {
    return `fomio-user-menu fomio-user-menu--${this.source}`;
  }

  get panelStyle() {
    if (
      this.source !== "desktop" ||
      !this.anchorRect ||
      typeof window === "undefined"
    ) {
      return null;
    }

    const sidebar = document.querySelector(".fomio-sidebar");
    const sidebarRect = sidebar ? sidebar.getBoundingClientRect() : null;
    const sidebarRight = sidebarRect ? sidebarRect.right : null;
    const preferredLeft =
      sidebarRight != null
        ? sidebarRight + this.DESKTOP_GAP
        : this.anchorRect.right + this.DESKTOP_GAP;
    const maxWidth = this.DESKTOP_WIDTH;
    const left = Math.max(
      this.DESKTOP_MARGIN,
      Math.min(
        preferredLeft,
        window.innerWidth - maxWidth - this.DESKTOP_MARGIN
      )
    );
    const menuHeight =
      this.measuredHeight > 0
        ? this.measuredHeight
        : Math.min(
            this.DESKTOP_MAX_HEIGHT,
            Math.round(window.innerHeight * 0.76)
          );
    const maxTop = window.innerHeight - menuHeight - this.DESKTOP_MARGIN;
    const preferredTop = this.anchorRect.bottom - menuHeight;
    const top = Math.max(this.DESKTOP_MARGIN, Math.min(preferredTop, maxTop));

    return `top:${Math.round(top)}px;left:${Math.round(left)}px;width:${Math.round(
      maxWidth
    )}px;`;
  }

  get title() {
    return this.currentUser?.username ?? i18n(themePrefix("user_overlay.title"));
  }

  get accountLabel() {
    return i18n(themePrefix("user_overlay.title"));
  }

  get ariaLabel() {
    return i18n(themePrefix("user_overlay.aria_label"));
  }

  get closeLabel() {
    return i18n(themePrefix("user_overlay.close"));
  }

  get sections() {
    const user = this.currentUser;
    if (!user) {
      return [];
    }

    const allSections = [
      {
        key: "summary",
        icon: "user",
        labelKey: "mobile_nav.me_hub_summary",
        subtitleKey: "user_overlay.summary",
        href: profileSummaryPathForUser(user),
      },
      {
        key: "activity",
        icon: "bars-staggered",
        labelKey: "mobile_nav.me_hub_activity",
        subtitleKey: "user_overlay.activity",
        href: activityPathForUser(user),
        isVisible: !this.siteSettings?.hide_user_activity_tab,
      },
      {
        key: "notifications",
        icon: "bell",
        labelKey: "mobile_nav.me_hub_notifications",
        subtitleKey: "user_overlay.notifications",
        href: notificationsPathForUser(user),
      },
      {
        key: "messages",
        icon: "envelope",
        labelKey: "mobile_nav.me_hub_messages",
        subtitleKey: "user_overlay.messages",
        href: messagesPathForUser(user),
        isVisible: Boolean(user?.can_send_private_messages),
      },
      {
        key: "invites",
        icon: "user-plus",
        labelKey: "mobile_nav.me_hub_invites",
        subtitleKey: "user_overlay.invites",
        href: invitedPathForUser(user),
        isVisible: Boolean(user?.can_invite_to_forum),
      },
      {
        key: "badges",
        icon: "certificate",
        labelKey: "mobile_nav.me_hub_badges",
        subtitleKey: "user_overlay.badges",
        href: badgesPathForUser(user),
        isVisible: Boolean(this.siteSettings?.enable_badges),
      },
    ];

    return allSections
      .filter((section) => section.href && section.isVisible !== false)
      .map((section) => ({
        ...section,
        label: i18n(themePrefix(section.labelKey)),
        subtitle: i18n(themePrefix(section.subtitleKey)),
        isActive: matchesPath(this.router.currentURL, section.href),
      }));
  }

  @action
  close() {
    this.isOpen = false;
    this.anchorRect = null;
    this.measuredHeight = 0;
    this._panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_USER_MENU_CLASS);
    publishFomioUserMenuState(false, this.source);
  }

  @action
  closeFromBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  @action
  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.close();
    }
  }

  @action
  setupPanel(element) {
    element.focus();

    const measure = () => {
      this.measuredHeight = Math.round(element.getBoundingClientRect().height);
    };

    measure();
    this._panelResizeObserver?.disconnect();
    if (typeof ResizeObserver !== "undefined") {
      this._panelResizeObserver = new ResizeObserver(() => measure());
      this._panelResizeObserver.observe(element);
    }
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="fomio-user-menu-shell"
        role="presentation"
        {{on "click" this.closeFromBackdrop}}
      >
        <div
          class={{this.panelClass}}
          style={{this.panelStyle}}
          role="dialog"
          aria-modal="true"
          aria-label={{this.ariaLabel}}
          tabindex="-1"
          {{didInsert this.setupPanel}}
          {{on "keydown" this.handleKeydown}}
        >
          <header class="fomio-user-menu__header">
            <span class="fomio-user-menu__identity">
              <span class="fomio-user-menu__title">{{this.title}}</span>
              <span class="fomio-user-menu__subtitle">{{this.accountLabel}}</span>
            </span>
            <FomioButton
              @variant="ghost"
              @size="sm"
              @iconOnly={{true}}
              @leadingIcon="xmark"
              @extraClass="fomio-user-menu__close"
              aria-label={{this.closeLabel}}
              {{on "click" this.close}}
            />
          </header>

          <FomioList @extraClass="fomio-user-menu__list">
            {{#each this.sections as |section|}}
              <FomioListItem
                @href={{section.href}}
                @leadingIcon={{section.icon}}
                @title={{section.label}}
                @subtitle={{section.subtitle}}
                @trailingIcon="angle-right"
                @isActive={{section.isActive}}
                @extraClass="fomio-user-menu__item"
                {{on "click" this.close}}
              />
            {{/each}}
          </FomioList>
        </div>
      </div>
    {{/if}}
  </template>
}
