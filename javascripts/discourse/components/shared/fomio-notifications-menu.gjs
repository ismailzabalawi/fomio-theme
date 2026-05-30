import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import MenuItem from "discourse/components/user-menu/menu-item";
import { ajax } from "discourse/lib/ajax";
import Notification from "discourse/models/notification";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import icon from "discourse/helpers/d-icon";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import {
  FOMIO_NOTIFICATIONS_MENU_CLASS,
  FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
  FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
  publishFomioNotificationsMenuState,
} from "../../lib/fomio-notifications-menu";

const TAB_ALL = "all";
const TAB_MESSAGES = "messages";
const DEFAULT_LIMIT = 30;
const MESSAGE_TYPES = ["private_message", "group_message_summary"];

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function dateGroupKey(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "earlier";
  }

  const today = startOfDay(new Date());
  const thatDay = startOfDay(date);
  const diffDays = Math.round((today - thatDay) / 86400000);

  if (diffDays <= 0) {
    return "today";
  }

  if (diffDays === 1) {
    return "yesterday";
  }

  return "earlier";
}

export default class FomioNotificationsMenu extends Component {
  DESKTOP_GAP = 12;
  DESKTOP_MARGIN = 16;
  DESKTOP_WIDTH = 420;
  DESKTOP_MAX_HEIGHT = 704;

  @service appEvents;
  @service currentUser;
  @service router;
  @service site;
  @service siteSettings;

  @tracked activeTab = TAB_ALL;
  @tracked allEntries = null;
  @tracked messageEntries = null;
  @tracked isLoading = false;
  @tracked isMarkingRead = false;
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

      const nextSource =
        event?.detail?.source === "mobile" ? "mobile" : "desktop";

      if (this.isOpen && this.source === nextSource) {
        this.close();
        return;
      }

      this.source = nextSource;
      this.anchorRect = event?.detail?.anchorRect ?? null;
      this.isOpen = true;
      document.body?.classList.add(FOMIO_NOTIFICATIONS_MENU_CLASS);
      publishFomioNotificationsMenuState(true, this.source);
      this.loadActiveTab();
    };

    this._handleClose = () => this.close();
    this._handleNotificationsChanged = () => {
      this.allEntries = null;
      this.messageEntries = null;

      if (this.isOpen) {
        this.loadActiveTab(true);
      }
    };

    if (typeof window !== "undefined") {
      window.addEventListener(
        FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
        this._handleOpen
      );
      window.addEventListener(
        FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
        this._handleClose
      );
    }

    this.appEvents.on(
      "notifications:changed",
      this,
      this._handleNotificationsChanged
    );
    this._onRouteDidChange = () => this.close();
    this.router.on("routeDidChange", this._onRouteDidChange);
  }

  willDestroy() {
    super.willDestroy(...arguments);

    if (typeof window !== "undefined") {
      window.removeEventListener(
        FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
        this._handleOpen
      );
      window.removeEventListener(
        FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
        this._handleClose
      );
    }

    this.appEvents.off(
      "notifications:changed",
      this,
      this._handleNotificationsChanged
    );
    this.router.off("routeDidChange", this._onRouteDidChange);
    this._panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_NOTIFICATIONS_MENU_CLASS);
    publishFomioNotificationsMenuState(false, this.source);
  }

  get shouldRender() {
    return Boolean(this.currentUser && this.isOpen);
  }

  get panelClass() {
    return `fomio-notifications-menu fomio-notifications-menu--${this.source}`;
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
        : this.anchorRect.right - this.DESKTOP_WIDTH;
    const maxWidth = Math.min(
      this.DESKTOP_WIDTH,
      Math.max(320, window.innerWidth - preferredLeft - this.DESKTOP_MARGIN)
    );
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
            Math.round(window.innerHeight * 0.82)
          );
    const maxTop = window.innerHeight - menuHeight - this.DESKTOP_MARGIN;
    const preferredTop = this.anchorRect.bottom - menuHeight;
    const top = Math.max(
      this.DESKTOP_MARGIN,
      Math.min(preferredTop, maxTop)
    );

    return `top:${Math.round(top)}px;left:${Math.round(left)}px;width:${Math.round(
      maxWidth
    )}px;`;
  }

  get ariaLabel() {
    return i18n(themePrefix("notifications_overlay.aria_label"));
  }

  get title() {
    return i18n(themePrefix("notifications_overlay.title"));
  }

  get showMobileCloseButton() {
    return this.source === "mobile";
  }

  get activeEntries() {
    return this.activeTab === TAB_MESSAGES
      ? this.messageEntries || []
      : this.allEntries || [];
  }

  get groupedEntries() {
    const groups = new Map();

    for (const entry of this.activeEntries) {
      const key = dateGroupKey(entry.createdAt);
      if (!groups.has(key)) {
        groups.set(key, []);
      }
      groups.get(key).push(entry);
    }

    return ["today", "yesterday", "earlier"]
      .filter((key) => groups.has(key))
      .map((key) => ({
        id: key,
        label: i18n(themePrefix(`notifications_overlay.groups.${key}`)),
        entries: groups.get(key),
      }));
  }

  get hasEntries() {
    return this.activeEntries.length > 0;
  }

  get showMarkAllRead() {
    return this.activeUnreadCount > 0;
  }

  get activeUnreadCount() {
    if (!this.currentUser) {
      return 0;
    }

    if (this.activeTab === TAB_MESSAGES) {
      return MESSAGE_TYPES.reduce((sum, type) => {
        const typeId = this.site.notification_types[type];
        return (
          sum + (typeId ? this.currentUser.get(`grouped_unread_notifications.${typeId}`) || 0 : 0)
        );
      }, 0);
    }

    return this.currentUser.all_unread_notifications_count || 0;
  }

  get markAllReadLabel() {
    return i18n(themePrefix("notifications_overlay.mark_all_read"));
  }

  get allTabLabel() {
    return i18n(themePrefix("notifications_overlay.tabs.all"));
  }

  get messagesTabLabel() {
    return i18n(themePrefix("notifications_overlay.tabs.messages"));
  }

  get allTabClass() {
    return this.activeTab === TAB_ALL
      ? "fomio-np-tab is-active"
      : "fomio-np-tab";
  }

  get messagesTabClass() {
    return this.activeTab === TAB_MESSAGES
      ? "fomio-np-tab is-active"
      : "fomio-np-tab";
  }

  get viewAllHref() {
    if (!this.currentUser) {
      return "#";
    }

    return this.activeTab === TAB_MESSAGES
      ? `${this.currentUser.path}/messages`
      : `${this.currentUser.path}/notifications`;
  }

  get viewAllLabel() {
    return i18n(
      themePrefix(
        this.activeTab === TAB_MESSAGES
          ? "notifications_overlay.view_all_messages"
          : "notifications_overlay.view_all_notifications"
      )
    );
  }

  get emptyTitle() {
    return i18n(
      themePrefix(
        this.activeTab === TAB_MESSAGES
          ? "notifications_overlay.empty_messages"
          : "notifications_overlay.empty_all"
      )
    );
  }

  async loadActiveTab(force = false) {
    if (!this.currentUser) {
      return;
    }

    const shouldLoad =
      force ||
      (this.activeTab === TAB_MESSAGES
        ? this.messageEntries === null
        : this.allEntries === null);

    if (!shouldLoad) {
      return;
    }

    this.isLoading = true;

    try {
      const entries =
        this.activeTab === TAB_MESSAGES
          ? await this.fetchNotificationEntries(MESSAGE_TYPES)
          : await this.fetchNotificationEntries();

      if (this.activeTab === TAB_MESSAGES) {
        this.messageEntries = entries;
      } else {
        this.allEntries = entries;
      }
    } finally {
      this.isLoading = false;
    }
  }

  async fetchNotificationEntries(filterByTypes = null) {
    const params = {
      limit: DEFAULT_LIMIT,
      recent: true,
      bump_last_seen_reviewable: true,
    };

    if (filterByTypes?.length) {
      params.filter_by_types = filterByTypes.join(",");
      params.silent = true;
    }

    if (this.currentUser.enforcedSecondFactor) {
      params.silent = true;
    }

    const data = await ajax("/notifications", { data: params });
    const notifications = await Notification.initializeNotifications(
      data.notifications || []
    );

    return notifications.map((notification) => {
      const item = new UserMenuNotificationItem({
        notification,
        appEvents: this.appEvents,
        currentUser: this.currentUser,
        siteSettings: this.siteSettings,
        site: this.site,
      });

      return {
        id: `notification-${notification.id}`,
        item,
        createdAt: notification.created_at,
      };
    });
  }

  @action
  async selectTab(tabId) {
    if (this.activeTab === tabId) {
      return;
    }

    this.activeTab = tabId;
    await this.loadActiveTab();
  }

  @action
  close() {
    this.isOpen = false;
    this.anchorRect = null;
    this.measuredHeight = 0;
    this.isLoading = false;
    this._panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_NOTIFICATIONS_MENU_CLASS);
    publishFomioNotificationsMenuState(false, this.source);
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

  @action
  async markAllRead() {
    if (this.isMarkingRead || !this.currentUser || this.activeUnreadCount <= 0) {
      return;
    }

    this.isMarkingRead = true;

    try {
      if (this.activeTab === TAB_MESSAGES) {
        await ajax("/notifications/mark-read", {
          type: "PUT",
          data: { dismiss_types: MESSAGE_TYPES.join(",") },
        });

        const groupedUnreadNotifications = {
          ...this.currentUser.grouped_unread_notifications,
        };
        let dismissedCount = 0;

        MESSAGE_TYPES.forEach((type) => {
          const typeId = this.site.notification_types[type];
          if (!typeId) {
            return;
          }

          dismissedCount += groupedUnreadNotifications[typeId] || 0;
          delete groupedUnreadNotifications[typeId];
        });

        this.currentUser.set(
          "grouped_unread_notifications",
          groupedUnreadNotifications
        );
        this.currentUser.set(
          "all_unread_notifications_count",
          Math.max(
            0,
            (this.currentUser.all_unread_notifications_count || 0) -
              dismissedCount
          )
        );
        this.currentUser.set("new_personal_messages_notifications_count", 0);
      } else {
        await ajax("/notifications/mark-read", { type: "PUT" });
        this.currentUser.set("all_unread_notifications_count", 0);
        this.currentUser.set("unread_high_priority_notifications", 0);
        this.currentUser.set("grouped_unread_notifications", {});
        this.currentUser.set("new_personal_messages_notifications_count", 0);
      }

      this.allEntries = null;
      this.messageEntries = null;
      await this.loadActiveTab(true);
      this.appEvents.trigger("notifications:changed");
    } finally {
      this.isMarkingRead = false;
    }
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="fomio-notifications-menu-shell"
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
          <header class="fomio-np-header">
            <span class="fomio-np-title">{{this.title}}</span>

            {{#if this.showMarkAllRead}}
              <button
                type="button"
                class="fomio-np-mark-all"
                disabled={{this.isMarkingRead}}
                {{on "click" this.markAllRead}}
              >
                {{this.markAllReadLabel}}
              </button>
            {{/if}}

            {{#if this.showMobileCloseButton}}
              <button
                type="button"
                class="fomio-np-close"
                aria-label={{this.ariaLabel}}
                {{on "click" this.close}}
              >
                {{icon "xmark"}}
              </button>
            {{/if}}
          </header>

          <div class="fomio-np-tabs" role="tablist" aria-label={{this.title}}>
            <button
              type="button"
              role="tab"
              aria-selected={{if (eq this.activeTab "all") "true" "false"}}
              class={{this.allTabClass}}
              {{on "click" (fn this.selectTab "all")}}
            >
              {{this.allTabLabel}}
            </button>

            <button
              type="button"
              role="tab"
              aria-selected={{if (eq this.activeTab "messages") "true" "false"}}
              class={{this.messagesTabClass}}
              {{on "click" (fn this.selectTab "messages")}}
            >
              {{this.messagesTabLabel}}
            </button>
          </div>

          <div class="fomio-np-body">
            {{#if this.isLoading}}
              <div class="fomio-np-empty-state">
                <div class="spinner small"></div>
              </div>
            {{else if this.hasEntries}}
              <div class="fomio-np-scroll">
                {{#each this.groupedEntries as |group|}}
                  <section class="fomio-np-section" data-group={{group.id}}>
                    <h3 class="fomio-np-section-title">{{group.label}}</h3>
                    <ul class="fomio-np-list">
                      {{#each group.entries as |entry|}}
                        <MenuItem @item={{entry.item}} @closeUserMenu={{this.close}} />
                      {{/each}}
                    </ul>
                  </section>
                {{/each}}
              </div>
            {{else}}
              <div class="fomio-np-empty-state">
                <p class="fomio-np-empty-title">{{this.emptyTitle}}</p>
              </div>
            {{/if}}
          </div>

          <footer class="fomio-np-footer">
            <a class="fomio-np-view-all" href={{this.viewAllHref}}>
              <span>{{this.viewAllLabel}}</span>
              {{icon "arrow-right"}}
            </a>
          </footer>
        </div>
      </div>
    {{/if}}
  </template>
}
