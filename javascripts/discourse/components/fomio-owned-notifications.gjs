import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import Notification from "discourse/models/notification";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import { i18n } from "discourse-i18n";
import { settings, themePrefix } from "virtual:theme";
import {
  normalizeOwnedNotificationsPayload,
  ownedNotificationsFilterPath,
  ownedNotificationsRequest,
  parseOwnedNotificationsRoute,
} from "../lib/fomio-owned-notifications";
import FomioButton from "./shared/fomio-button";
import FomioEmptyState from "./shared/fomio-empty-state";
import FomioMeFilterChips from "./shared/fomio-me-filter-chips";
import FomioNotificationsMenuItem from "./shared/fomio-notifications-menu-item";

const READY_CLASS = "fomio-owned-notifications-ready";
const CONVERSATION_TYPE_CLASSES = [
  "mentioned",
  "replied",
  "quoted",
  "group-mentioned",
  "private-message",
  "invited-to-private-message",
  "invitee-accepted",
  "posted",
  "moved-post",
  "linked",
  "watching-first-post",
  "group-message-summary",
  "invited-to-topic",
];
const REACTION_TYPE_CLASSES = ["liked", "liked-consolidated", "reaction"];

export default class FomioOwnedNotifications extends Component {
  @service appEvents;
  @service currentUser;
  @service router;
  @service site;
  @service siteSettings;

  @tracked entries = [];
  @tracked isLoading = false;
  @tracked isLoadingMore = false;
  @tracked error = null;
  @tracked loadMoreUrl = null;
  @tracked activeFilter = null;
  @tracked activeTypeFilter = "all";

  #routeHandler = () => {
    this.loadInitial();
  };

  constructor() {
    super(...arguments);
    this.router.on?.("routeDidChange", this.#routeHandler);
    this.loadInitial();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off?.("routeDidChange", this.#routeHandler);
    this.#setReady(false);
  }

  get routeState() {
    if (this.args.routeState) {
      return {
        ...this.args.routeState,
        filter: this.activeFilter,
      };
    }

    return parseOwnedNotificationsRoute(this.router.currentURL, this.currentUser);
  }

  get shouldRender() {
    return (
      (this.args.detached || settings.fomio_owned_me_notifications_enabled) &&
      Boolean(this.currentUser) &&
      this.routeState?.isIndex
    );
  }

  get titleLabel() {
    return i18n(themePrefix("owned_notifications.title"));
  }

  get typeFilters() {
    return [
      { id: "all", labelKey: "me_filter_chips.notifications.all" },
      { id: "conversations", labelKey: "me_filter_chips.notifications.conversations" },
      { id: "reactions", labelKey: "me_filter_chips.notifications.reactions" },
      { id: "system", labelKey: "me_filter_chips.notifications.system" },
    ];
  }

  get loadingLabel() {
    return i18n(themePrefix("owned_notifications.loading"));
  }

  get loadMoreLabel() {
    return i18n(themePrefix("owned_notifications.load_more"));
  }

  get emptyTitle() {
    return i18n(themePrefix("owned_notifications.empty.title"));
  }

  get emptyBody() {
    return i18n(themePrefix("owned_notifications.empty.body"));
  }

  get typeFilterEmptyLabel() {
    return i18n(themePrefix("me_filter_chips.notifications.empty"));
  }

  get errorTitle() {
    return i18n(themePrefix("owned_notifications.error.title"));
  }

  get errorBody() {
    return i18n(themePrefix("owned_notifications.error.body"));
  }

  get retryLabel() {
    return i18n(themePrefix("owned_notifications.error.retry"));
  }

  get filters() {
    return [
      {
        id: null,
        label: i18n(themePrefix("owned_notifications.filters.all")),
        className: this.filterClassName(null),
      },
      {
        id: "unread",
        label: i18n(themePrefix("owned_notifications.filters.unread")),
        className: this.filterClassName("unread"),
      },
      {
        id: "read",
        label: i18n(themePrefix("owned_notifications.filters.read")),
        className: this.filterClassName("read"),
      },
    ];
  }

  get isInitialLoading() {
    return this.isLoading && !this.entries.length;
  }

  get hasEntries() {
    return this.entries.length > 0;
  }

  get groupedEntries() {
    const groups = [];
    const groupMap = new Map();

    this.filteredEntries.forEach((entry) => {
      const id = this.dayGroupId(entry.createdAt);
      let group = groupMap.get(id);

      if (!group) {
        group = {
          id,
          label: this.dayGroupLabel(entry.createdAt),
          entries: [],
        };
        groupMap.set(id, group);
        groups.push(group);
      }

      group.entries.push(entry);
    });

    return groups;
  }

  get filteredEntries() {
    return this.entries.filter((entry) => this.matchesTypeFilter(entry));
  }

  get hasVisibleEntries() {
    return this.groupedEntries.length > 0;
  }

  matchesTypeFilter(entry) {
    if (this.activeTypeFilter === "all") {
      return true;
    }

    const className = entry.item.className || "";
    const hasClass = (name) => className.split(/\s+/).includes(name);
    const isConversation = CONVERSATION_TYPE_CLASSES.some(hasClass);
    const isReaction = REACTION_TYPE_CLASSES.some(hasClass);

    if (this.activeTypeFilter === "conversations") {
      return isConversation;
    }

    if (this.activeTypeFilter === "reactions") {
      return isReaction;
    }

    if (this.activeTypeFilter === "system") {
      return !isConversation && !isReaction;
    }

    return true;
  }

  filterClassName(filter) {
    return [
      "fomio-owned-notifications__filter",
      this.activeFilter === filter
        ? "fomio-owned-notifications__filter--active"
        : null,
    ]
      .filter(Boolean)
      .join(" ");
  }

  async loadInitial() {
    if (!this.shouldRender) {
      this.#setReady(false);
      return;
    }

    const routeState = this.routeState;
    this.activeFilter = routeState.filter;
    this.isLoading = true;
    this.error = null;
    this.#setReady(false);

    try {
      const payload = await this.#fetchPayload(routeState);
      this.entries = await this.#entriesFromPayload(payload.notifications);
      this.loadMoreUrl = payload.loadMoreUrl;
      this.#setReady(true);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("[Fomio] Notifications: failed to load owned inbox", error);
      this.entries = [];
      this.loadMoreUrl = null;
      this.error = error;
      this.#setReady(false);
    } finally {
      this.isLoading = false;
    }
  }

  async #fetchPayload(routeState, options = {}) {
    const request = ownedNotificationsRequest(routeState, options);
    const ajaxOptions = request.data ? { data: request.data } : undefined;
    const response = await ajax(request.url, ajaxOptions);
    return normalizeOwnedNotificationsPayload(response);
  }

  async #entriesFromPayload(notifications) {
    const initialized = await Notification.initializeNotifications(notifications);

    return initialized.map((notification) => {
      const item = new UserMenuNotificationItem({
        notification,
        appEvents: this.appEvents,
        currentUser: this.currentUser,
        siteSettings: this.siteSettings,
        site: this.site,
      });

      return {
        id: notification.id,
        createdAt: notification.created_at,
        item: this.#renderableItem(item, notification),
      };
    });
  }

  #renderableItem(item, notification) {
    const className = [
      "fomio-owned-notifications__row",
      item.className,
      notification.read ? "is-read" : "is-unread",
      notification.high_priority ? "is-high-priority" : null,
    ]
      .filter(Boolean)
      .join(" ");

    return {
      get className() {
        return className;
      },
      get linkHref() {
        return item.linkHref;
      },
      get linkTitle() {
        return item.linkTitle;
      },
      get icon() {
        return item.icon;
      },
      get label() {
        return item.label;
      },
      get labelClass() {
        return item.labelClass;
      },
      get description() {
        return item.description;
      },
      get descriptionClass() {
        return item.descriptionClass;
      },
      get topicId() {
        return item.topicId;
      },
      get iconComponent() {
        return item.iconComponent;
      },
      get iconComponentArgs() {
        return item.iconComponentArgs;
      },
      get endComponent() {
        return item.endComponent;
      },
      get endOutletArgs() {
        return item.endOutletArgs;
      },
      onClick(args) {
        return item.onClick(args);
      },
    };
  }

  dayGroupId(createdAt) {
    const date = new Date(createdAt);

    if (Number.isNaN(date.getTime())) {
      return "unknown";
    }

    return date.toISOString().slice(0, 10);
  }

  dayGroupLabel(createdAt) {
    const date = new Date(createdAt);

    if (Number.isNaN(date.getTime())) {
      return i18n(themePrefix("owned_notifications.sections.older"));
    }

    const today = new Date();
    const todayId = this.dayGroupId(today);
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);

    if (this.dayGroupId(date) === todayId) {
      return i18n(themePrefix("owned_notifications.sections.today"));
    }

    if (this.dayGroupId(date) === this.dayGroupId(yesterday)) {
      return i18n(themePrefix("owned_notifications.sections.yesterday"));
    }

    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: date.getFullYear() === today.getFullYear() ? undefined : "numeric",
    });
  }

  #setReady(isReady) {
    document.body?.classList.toggle(READY_CLASS, Boolean(isReady));
  }

  @action
  selectTypeFilter(filter) {
    this.activeTypeFilter = filter;
  }

  @action
  selectFilter(filter) {
    if (this.activeFilter === filter) {
      return;
    }

    if (this.args.detached) {
      this.activeFilter = filter;
      this.loadInitial();
      return;
    }

    this.router.transitionTo(
      ownedNotificationsFilterPath(this.routeState, this.router.currentURL, filter)
    );
  }

  @action
  retry() {
    this.loadInitial();
  }

  @action
  async loadMore() {
    if (!this.loadMoreUrl || this.isLoadingMore) {
      return;
    }

    this.isLoadingMore = true;

    try {
      const payload = await this.#fetchPayload(this.routeState, {
        loadMoreUrl: this.loadMoreUrl,
      });
      const entries = await this.#entriesFromPayload(payload.notifications);
      this.entries = [...this.entries, ...entries];
      this.loadMoreUrl = payload.loadMoreUrl;
      this.#setReady(true);
    } catch (error) {
      // Do not unset the owned layer after the initial successful render.
      // eslint-disable-next-line no-console
      console.error("[Fomio] Notifications: failed to load more", error);
    } finally {
      this.isLoadingMore = false;
    }
  }

  <template>
    {{#if this.shouldRender}}
      <section
        class="fomio-owned-notifications"
        aria-labelledby="fomio-owned-notifications-title"
      >
        <header class="fomio-owned-notifications__header">
          <h1 id="fomio-owned-notifications-title" class="sr-only">
            {{this.titleLabel}}
          </h1>
          <FomioMeFilterChips
            @dataAttributeName="data-fomio-me-notifications-filter"
            @groupLabelKey="me_filter_chips.notifications.nav_aria"
            @filters={{this.typeFilters}}
            @initialFilterId="all"
            @onSelect={{this.selectTypeFilter}}
          />
          <nav
            class="fomio-owned-notifications__filters"
            aria-label={{this.titleLabel}}
          >
            {{#each this.filters as |filter|}}
              <button
                class={{filter.className}}
                type="button"
                {{on "click" (fn this.selectFilter filter.id)}}
              >
                {{filter.label}}
              </button>
            {{/each}}
          </nav>
        </header>

        {{#if this.isInitialLoading}}
          <div class="fomio-owned-notifications__loading" role="status">
            <div class="spinner small"></div>
            <span>{{this.loadingLabel}}</span>
          </div>
        {{else if this.error}}
          <FomioEmptyState
            @variant="centered"
            @icon="triangle-exclamation"
            @title={{this.errorTitle}}
            @body={{this.errorBody}}
            @extraClass="fomio-owned-notifications__state"
          >
            <FomioButton @variant="secondary" {{on "click" this.retry}}>
              {{this.retryLabel}}
            </FomioButton>
          </FomioEmptyState>
        {{else if this.hasEntries}}
          <div class="fomio-owned-notifications__timeline">
            {{#if this.hasVisibleEntries}}
              {{#each this.groupedEntries as |group|}}
                <section class="fomio-owned-notifications__group">
                  <h2 class="fomio-owned-notifications__group-title">
                    {{group.label}}
                  </h2>

                  <ul class="fomio-owned-notifications__list">
                    {{#each group.entries as |entry|}}
                      <FomioNotificationsMenuItem @item={{entry.item}} />
                    {{/each}}
                  </ul>
                </section>
              {{/each}}
            {{else}}
              <p class="fomio-me-filter-chips__empty" role="status">
                {{this.typeFilterEmptyLabel}}
              </p>
            {{/if}}
          </div>

          {{#if this.loadMoreUrl}}
            <footer class="fomio-owned-notifications__footer">
              <FomioButton
                @variant="secondary"
                @isDisabled={{this.isLoadingMore}}
                {{on "click" this.loadMore}}
              >
                {{this.loadMoreLabel}}
              </FomioButton>
            </footer>
          {{/if}}
        {{else}}
          <FomioEmptyState
            @variant="centered"
            @icon="bell"
            @title={{this.emptyTitle}}
            @body={{this.emptyBody}}
            @extraClass="fomio-owned-notifications__state"
          />
        {{/if}}
      </section>
    {{/if}}
  </template>
}
