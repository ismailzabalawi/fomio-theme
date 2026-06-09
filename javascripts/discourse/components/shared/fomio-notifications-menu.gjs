import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { ajax } from "discourse/lib/ajax";
import Notification from "discourse/models/notification";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioButton from "./fomio-button";
import FomioEmptyState from "./fomio-empty-state";
import FomioList from "./fomio-list";
import FomioListItem from "./fomio-list-item";
import FomioNotificationsMenuItem from "./fomio-notifications-menu-item";
import FomioListSectionHeader from "./fomio-list-section-header";
import FomioTabs from "./fomio-tabs";
import {
  FOMIO_NOTIFICATIONS_MENU_CLASS,
  FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
  FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
  publishFomioNotificationsMenuState,
} from "../../lib/fomio-notifications-menu";
import { notificationsMenuClassNames } from "../../lib/fomio-interaction-classes";
import {
  notificationsPathForUser,
} from "../../lib/fomio-mobile-nav-paths";

const TAB_ALL = "all";
const TAB_RESPONSES = "responses";
const TAB_LIKES = "likes";
const TAB_MENTIONS = "mentions";
const TAB_EDITS = "edits";
const TAB_LINKS = "links";
const DEFAULT_LIMIT = 30;

const TAB_CONFIGS = [
  {
    key: TAB_ALL,
    labelKey: "user.filters.all",
    emptyTitleKey: "notifications_overlay.empty_all",
    icon: "bell",
    notificationTypes: null,
    hrefSuffix: "/notifications",
  },
  {
    key: TAB_RESPONSES,
    labelKey: "user_action_groups.5",
    emptyTitleKey: "notifications_overlay.empty_responses",
    icon: "reply",
    notificationTypes: ["posted", "quoted", "replied"],
    hrefSuffix: "/notifications/responses",
  },
  {
    key: TAB_LIKES,
    labelKey: "user_action_groups.2",
    emptyTitleKey: "notifications_overlay.empty_likes",
    icon: "heart",
    notificationTypes: ["liked", "liked_consolidated", "reaction"],
    hrefSuffix: "/notifications/likes-received",
  },
  {
    key: TAB_MENTIONS,
    labelKey: "user_action_groups.7",
    emptyTitleKey: "notifications_overlay.empty_mentions",
    icon: "at",
    notificationTypes: ["mentioned", "group_mentioned"],
    hrefSuffix: "/notifications/mentions",
    shouldDisplay({ siteSettings }) {
      return Boolean(siteSettings.enable_mentions);
    },
  },
  {
    key: TAB_EDITS,
    labelKey: "user_action_groups.11",
    emptyTitleKey: "notifications_overlay.empty_edits",
    icon: "pencil",
    notificationTypes: ["edited"],
    hrefSuffix: "/notifications/edits",
  },
  {
    key: TAB_LINKS,
    labelKey: "user_action_groups.17",
    emptyTitleKey: "notifications_overlay.empty_links",
    icon: "link",
    notificationTypes: ["linked", "linked_consolidated"],
    hrefSuffix: "/notifications/links",
  },
];

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

function groupedEntriesFor(entries) {
  const groups = new Map();

  for (const entry of entries) {
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
  @tracked entriesByTab = {};
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

      const nextSource = event?.detail?.source === "mobile" ? "mobile" : "desktop";

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
      this.entriesByTab = {};

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
    return notificationsMenuClassNames(this.source, this.args.extraClass);
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

  get allUnreadCount() {
    return this.currentUser?.all_unread_notifications_count || 0;
  }

  get visibleTabs() {
    return TAB_CONFIGS.filter(
      (tab) => !tab.shouldDisplay || tab.shouldDisplay(this)
    );
  }

  get showMarkAllRead() {
    return this.activeUnreadCount > 0;
  }

  get activeUnreadCount() {
    return this.unreadCountForTab(this.activeTab);
  }

  get markAllReadLabel() {
    return i18n(themePrefix("notifications_overlay.mark_all_read"));
  }

  get tabs() {
    return this.visibleTabs.map((tab) => {
      const entries = this.entriesForTab(tab.key);

      return {
        key: tab.key,
        label: i18n(tab.labelKey),
        badge: this.unreadCountForTab(tab.key) || null,
        icon: tab.icon,
        emptyTitle: i18n(themePrefix(tab.emptyTitleKey)),
        groupedEntries: groupedEntriesFor(entries),
        hasEntries: entries.length > 0,
        isLoading: this.isLoading && this.activeTab === tab.key,
      };
    });
  }

  get viewAllHref() {
    if (!this.currentUser) {
      return "#";
    }

    const activeConfig = this.tabConfigFor(this.activeTab);

    if (!activeConfig) {
      return notificationsPathForUser(this.currentUser) ?? "#";
    }

    return `${this.currentUser.path}${activeConfig.hrefSuffix}`;
  }

  get viewAllLabel() {
    return i18n(themePrefix("notifications_overlay.view_all_notifications"));
  }

  tabConfigFor(tabId) {
    return this.visibleTabs.find((tab) => tab.key === tabId) ?? null;
  }

  entriesForTab(tabId) {
    return this.entriesByTab[tabId] || [];
  }

  unreadCountForTypes(types) {
    if (!this.currentUser || !types?.length) {
      return 0;
    }

    return types.reduce((sum, type) => {
      const typeId = this.site.notification_types[type];
      return (
        sum +
        (typeId
          ? this.currentUser.get(`grouped_unread_notifications.${typeId}`) || 0
          : 0)
      );
    }, 0);
  }

  unreadCountForTab(tabId) {
    if (tabId === TAB_ALL) {
      return this.allUnreadCount;
    }

    const tab = this.tabConfigFor(tabId);
    return this.unreadCountForTypes(tab?.notificationTypes);
  }

  async loadActiveTab(force = false) {
    if (!this.currentUser) {
      return;
    }

    const currentEntries = this.entriesByTab[this.activeTab];
    const shouldLoad = force || currentEntries === undefined;

    if (!shouldLoad) {
      return;
    }

    this.isLoading = true;

    try {
      const tab = this.tabConfigFor(this.activeTab);
      const entries = await this.fetchNotificationEntries(
        tab?.notificationTypes ?? null
      );

      this.entriesByTab = {
        ...this.entriesByTab,
        [this.activeTab]: entries,
      };
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
      const activeTypes = this.tabConfigFor(this.activeTab)?.notificationTypes;

      if (activeTypes?.length) {
        await ajax("/notifications/mark-read", {
          type: "PUT",
          data: { dismiss_types: activeTypes.join(",") },
        });

        const groupedUnreadNotifications = {
          ...this.currentUser.grouped_unread_notifications,
        };
        let dismissedCount = 0;

        activeTypes.forEach((type) => {
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
      } else {
        await ajax("/notifications/mark-read", { type: "PUT" });
        this.currentUser.set("all_unread_notifications_count", 0);
        this.currentUser.set("unread_high_priority_notifications", 0);
        this.currentUser.set("grouped_unread_notifications", {});
      }

      this.entriesByTab = {};
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
              <FomioButton
                @variant="ghost"
                @size="sm"
                @loading={{this.isMarkingRead}}
                @extraClass="fomio-np-mark-all"
                {{on "click" this.markAllRead}}
              >
                {{this.markAllReadLabel}}
              </FomioButton>
            {{/if}}

            {{#if this.showMobileCloseButton}}
              <FomioButton
                @variant="ghost"
                @size="sm"
                @iconOnly={{true}}
                @leadingIcon="xmark"
                @extraClass="fomio-np-close"
                aria-label={{this.ariaLabel}}
                {{on "click" this.close}}
              />
            {{/if}}
          </header>

          <FomioTabs
            @tabs={{this.tabs}}
            @selectedKey={{this.activeTab}}
            @onSelect={{this.selectTab}}
            @ariaLabel={{this.title}}
            @extraClass="fomio-np-tabs"
            as |tab|
          >
            {{#if tab.isLoading}}
              <div class="fomio-np-loading-state">
                <div class="spinner small"></div>
              </div>
            {{else if tab.hasEntries}}
              <div class="fomio-np-scroll">
                {{#each tab.groupedEntries as |group|}}
                  <FomioList @extraClass="fomio-np-list" data-group={{group.id}}>
                    <FomioListSectionHeader
                      @title={{group.label}}
                      @extraClass="fomio-np-section-title"
                    />

                    {{#each group.entries as |entry|}}
                      <FomioNotificationsMenuItem
                        @item={{entry.item}}
                        @closeUserMenu={{this.close}}
                      />
                    {{/each}}
                  </FomioList>
                {{/each}}
              </div>
            {{else}}
              <div class="fomio-np-empty-state">
                <FomioEmptyState
                  @variant="centered"
                  @icon={{tab.icon}}
                  @title={{tab.emptyTitle}}
                  @extraClass="fomio-np-empty-card"
                />
              </div>
            {{/if}}
          </FomioTabs>

          <footer class="fomio-np-footer">
            <FomioList @tag="nav" @extraClass="fomio-np-footer-list" aria-label={{this.viewAllLabel}}>
              <FomioListItem
                @wrapperTag="div"
                @tag="a"
                @href={{this.viewAllHref}}
                @title={{this.viewAllLabel}}
                @trailingIcon="arrow-right"
                @extraClass="fomio-np-view-all-row"
                {{on "click" this.close}}
              />
            </FomioList>
          </footer>
        </div>
      </div>
    {{/if}}
  </template>
}
