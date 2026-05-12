import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import { themePrefix, settings } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import { and, not, eq } from "discourse/truth-helpers";
import { on } from "@ember/modifier";
import { service } from "@ember/service";

import { fomioPathnameNoQuery, fomioPathsEqual } from "../lib/fomio-router-pathname";
import icon from "discourse/helpers/d-icon";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { fn } from "@ember/helper";


const NOTIFICATIONS_INDEX_LIMIT = 60;

/** Inbox only: `/u/:user/notifications` or same with trailing slash — no /responses|likes-received|… */
const USER_NOTIFICATIONS_INBOX_PATH =
  /^\/u\/([^/]+)\/notifications\/?$/;

const NOTIFICATION_TYPE_MAP = {
  1: "mentioned",
  2: "replied",
  3: "quoted",
  4: "edited",
  5: "liked",
  6: "private_message",
  7: "invited_to_private_message",
  8: "invitee_accepted",
  9: "posted",
  10: "moved_post",
  11: "linked",
  12: "granted_badge",
  13: "invited_to_topic",
  14: "custom",
  15: "group_mentioned",
  16: "group_message_summary",
  17: "watching_first_post",
  18: "topic_reminder",
  19: "liked_consolidated",
  20: "post_approved",
  21: "code_review_commit_approved",
  22: "membership_request_accepted",
  23: "membership_request_consolidated",
  24: "bookmark_reminder",
  25: "reaction",
  26: "votes_released",
};

/** Maps Discourse notification families → Fomio inbox display labels (locale: `display.*`). */
const INTERNAL_TO_DISPLAY = {
  mentioned: "mention",
  replied: "conversation",
  quoted: "conversation",
  edited: "update",
  liked: "reaction",
  private_message: "conversation",
  invited_to_private_message: "conversation",
  invitee_accepted: "conversation",
  posted: "conversation",
  moved_post: "update",
  linked: "link",
  granted_badge: "system",
  invited_to_topic: "conversation",
  custom: "system",
  group_mentioned: "mention",
  group_message_summary: "conversation",
  watching_first_post: "conversation",
  topic_reminder: "system",
  liked_consolidated: "reaction",
  post_approved: "system",
  code_review_commit_approved: "system",
  membership_request_accepted: "system",
  membership_request_consolidated: "system",
  bookmark_reminder: "system",
  reaction: "reaction",
  votes_released: "system",
  unknown: "notification",
};

function normalizeType(notificationType) {
  if (typeof notificationType === "number") {
    return NOTIFICATION_TYPE_MAP[notificationType] || "unknown";
  }
  return "unknown";
}

function displayCategory(internalKey) {
  if (!internalKey || typeof internalKey !== "string") {
    return "notification";
  }
  return INTERNAL_TO_DISPLAY[internalKey] || "notification";
}

function formatRelativeTime(iso) {
  if (!iso) {
    return "";
  }
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) {
    return "";
  }
  const diffSec = Math.round((then - Date.now()) / 1000);
  const abs = Math.abs(diffSec);
  const rtf = new Intl.RelativeTimeFormat(undefined, { numeric: "auto" });
  if (abs < 45) {
    return rtf.format(Math.round(diffSec / 60), "minute");
  }
  if (abs < 3600) {
    return rtf.format(Math.round(diffSec / 60), "minute");
  }
  if (abs < 86400) {
    return rtf.format(Math.round(diffSec / 3600), "hour");
  }
  if (abs < 604800) {
    return rtf.format(Math.round(diffSec / 86400), "day");
  }
  return rtf.format(Math.round(diffSec / 604800), "week");
}

function stripHtml(s) {
  if (!s || typeof s !== "string") {
    return "";
  }
  return s
    .replace(/<[^>]*>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function notificationTitle(n) {
  const data = n.data || {};
  return (
    n.fancy_title ||
    data.topic_title ||
    data.display_username ||
    data.badge_name ||
    ""
  );
}

function notificationExcerpt(n) {
  const data = n.data || {};
  const raw =
    data.excerpt || data.badge_description || data.group_name || "";
  return stripHtml(String(raw));
}

function notificationHref(n) {
  if (n.topic_id) {
    const slug = n.slug || "topic";
    const id = n.topic_id;
    const pn = n.post_number;
    if (pn && pn > 1) {
      return getURL(`/t/${slug}/${id}/${pn}`);
    }
    return getURL(`/t/${slug}/${id}`);
  }
  const data = n.data || {};
  if (data.topic_id) {
    const slug = data.slug || "topic";
    const id = data.topic_id;
    return getURL(`/t/${slug}/${id}`);
  }
  return getURL("/");
}

function startOfLocalDayMs(d) {
  const x = new Date(d);
  return new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
}

export default class FomioOwnedNotifications extends Component {
  #alive = true;
  #loadGeneration = 0;
  #onRouteDidChange = () => this.syncFromRoute();

  @service router;
  @service currentUser;

  @tracked loading = true;
  @tracked loadingMore = false;
  @tracked failed = false;
  @tracked items = [];
  @tracked nextPath = null;
  @tracked dismissing = false;
  didSuppressNative = false;

  @service siteSettings;

  @tracked pluginRows = [];
  /** When false, accordion follows active route group. */
  @tracked disclosureUserOverride = false;
  /** Expanded panel when overriden; 'none' = all collapsed. */
  @tracked disclosureExpandedId = null;

  get pathNoQuery() {
    return fomioPathnameNoQuery(this.router.currentURL);
  }

  get username() {
    const m = /^\/u\/([^/]+)\/notifications/.exec(this.pathNoQuery);
    if (m) {
      return decodeURIComponent(m[1]);
    }
    if (
      this.pathNoQuery === "/notifications" ||
      this.pathNoQuery.startsWith("/notifications/")
    ) {
      return this.currentUser?.username ?? null;
    }
    return null;
  }

  get basePath() {
    const u = this.username;
    return u ? `/u/${u}/notifications` : null;
  }

  isActiveForPath(suffix) {
    const base = this.basePath;
    if (!base) return false;
    if (suffix === "") return fomioPathsEqual(this.pathNoQuery, base);
    return fomioPathsEqual(this.pathNoQuery, `${base}/${suffix}`);
  }

  normalizePathForCompare(href) {
    try {
      const u = new URL(href, window.location.origin);
      return u.pathname;
    } catch {
      return href.split("?")[0];
    }
  }

  isActivePath(fullPath) {
    return fomioPathsEqual(this.pathNoQuery, fullPath);
  }

  get coreRows() {
    const base = this.basePath;
    if (!base) return [];

    const out = [
      {
        id: "all",
        href: getURL(base),
        label: i18n("user.filters.all"),
        isActive: this.isActiveForPath(""),
      },
      {
        id: "responses",
        href: getURL(`${base}/responses`),
        label: i18n("user_action_groups.5"),
        isActive: this.isActiveForPath("responses"),
      },
    ];

    if (this.siteSettings.enable_mentions) {
      out.push({
        id: "mentions",
        href: getURL(`${base}/mentions`),
        label: i18n("user_action_groups.7"),
        isActive: this.isActiveForPath("mentions"),
      });
    }

    out.push(
      {
        id: "likes-received",
        href: getURL(`${base}/likes-received`),
        label: i18n("user_action_groups.2"),
        isActive: this.isActiveForPath("likes-received"),
      },
      {
        id: "links",
        href: getURL(`${base}/links`),
        label: i18n("user_action_groups.17"),
        isActive: this.isActiveForPath("links"),
      },
      {
        id: "edits",
        href: getURL(`${base}/edits`),
        label: i18n("user_action_groups.11"),
        isActive: this.isActiveForPath("edits"),
      }
    );

    return out;
  }

  get allNavRows() {
    const plugins = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));
    return [...this.coreRows, ...plugins];
  }

  rowGroupId(rowId) {
    if (String(rowId).startsWith("plugin-")) {
      return "more";
    }
    switch (rowId) {
      case "all":
        return "all";
      case "responses":
      case "mentions":
        return "conversations";
      case "likes-received":
      case "links":
        return "engagement";
      case "edits":
        return "changes";
      default:
        return "more";
    }
  }

  get activeGroupId() {
    const row = this.allNavRows.find((r) => r.isActive);
    if (!row) {
      return "all";
    }
    return this.rowGroupId(row.id);
  }

  get openDisclosureGroupId() {
    if (!this.disclosureUserOverride) {
      return this.activeGroupId;
    }
    return this.disclosureExpandedId;
  }

  get disclosureGroups() {
    const base = this.basePath;
    if (!base) {
      return [];
    }

    const rowById = new Map(this.coreRows.map((r) => [r.id, r]));

    const mk = (id, labelKey, rowIds) => {
      const rows = rowIds
        .map((rid) => rowById.get(rid))
        .filter(Boolean);
      return {
        id,
        label: i18n(themePrefix(labelKey)),
        panelId: `fomio-owned-notifications-panel-${id}`,
        triggerId: `fomio-owned-notifications-trigger-${id}`,
        rows,
      };
    };

    const groups = [
      mk("all", "notifications_submenu.group_all", ["all"]),
      mk("conversations", "notifications_submenu.group_conversations", [
        "responses",
        ...(this.siteSettings.enable_mentions ? ["mentions"] : []),
      ]),
      mk("engagement", "notifications_submenu.group_engagement", [
        "likes-received",
        "links",
      ]),
      mk("changes", "notifications_submenu.group_changes", ["edits"]),
    ];

    const moreRows = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));

    if (moreRows.length > 0) {
      groups.push({
        id: "more",
        label: i18n(themePrefix("notifications_submenu.group_more")),
        panelId: "fomio-owned-notifications-panel-more",
        triggerId: "fomio-owned-notifications-trigger-more",
        rows: moreRows,
      });
    }

    return groups;
  }

  @action
  toggleDisclosureGroup(groupId) {
    const cur = this.openDisclosureGroupId;
    this.disclosureUserOverride = true;
    if (cur === groupId) {
      this.disclosureExpandedId = "none";
    } else {
      this.disclosureExpandedId = groupId;
    }
  }

  @action
  extractPluginRows() {
    const nav = document.querySelector("#main-outlet .user-main .user-navigation.user-navigation-secondary");
    const horiz = nav?.querySelector(":scope > nav.horizontal-overflow-nav");
    if (!horiz) return;
    const CORE_NOTIFICATIONS_NAV_SUBSTR = "user-nav__notifications-";
    const pills = horiz.querySelectorAll("ul.nav-pills > li");
    const out = [];
    pills.forEach((li, index) => {
      const cls = li.className?.toString() ?? "";
      if (cls.includes(CORE_NOTIFICATIONS_NAV_SUBSTR)) {
        return;
      }
      const a = li.querySelector("a[href]");
      if (!a) return;
      const rawHref = a.getAttribute("href");
      const label = (a.textContent || "").trim().replace(/\s+/g, " ");
      if (!rawHref || !label) return;
      out.push({
        id: `plugin-${index}-${getURL(rawHref)}`,
        href: getURL(rawHref),
        label,
      });
    });
    this.pluginRows = out;
  }


  get enabled() {
    return Boolean(settings.fomio_owned_me_notifications_enabled);
  }

  get hasItems() {
    return this.items.length > 0;
  }

  get unreadCount() {
    return this.items.filter((n) => n && !n.read).length;
  }

  get showLoadMore() {
    return Boolean(this.nextPath) && this.hasItems;
  }

  get skeletonPlaceholders() {
    return [0, 1, 2, 3];
  }

  @cached
  get groupedNotificationSections() {
    if (!this.hasItems) {
      return [];
    }
    const now = new Date();
    const startToday = startOfLocalDayMs(now);
    const startYesterday = startToday - 86400000;

    const buckets = {
      today: [],
      yesterday: [],
      earlier: [],
    };

    for (const item of this.items) {
      if (!item) {
        continue;
      }
      const ts = new Date(item.created_at).getTime();
      if (Number.isNaN(ts)) {
        buckets.earlier.push(item);
      } else if (ts >= startToday) {
        buckets.today.push(item);
      } else if (ts >= startYesterday) {
        buckets.yesterday.push(item);
      } else {
        buckets.earlier.push(item);
      }
    }

    const sections = [
      ["today", "group_today"],
      ["yesterday", "group_yesterday"],
      ["earlier", "group_earlier"],
    ];

    return sections
      .map(([key, i18nKey]) => ({
        key,
        label: i18n(themePrefix(`me_owned_notifications.${i18nKey}`)),
        items: buckets[key],
      }))
      .filter((g) => g.items.length > 0);
  }

  constructor() {
    super(...arguments);
    this.router.on("routeDidChange", this.#onRouteDidChange);
    if (this.enabled) {
      this.syncFromRoute();
    } else {
      this.loading = false;
    }
  }

  willDestroy() {
    this.#alive = false;
    this.router.off("routeDidChange", this.#onRouteDidChange);
    super.willDestroy();
    if (this.didSuppressNative) {
      document.body.classList.remove("fomio-owned-notifications--replaced");
    }
  }

  normalizeLoadMore(raw) {
    if (!raw || typeof raw !== "string") {
      return null;
    }
    const trimmed = raw.trim();
    if (!trimmed) {
      return null;
    }
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      try {
        const u = new URL(trimmed);
        return `${u.pathname}${u.search}`;
      } catch {
        return null;
      }
    }
    return trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
  }

  applyNativeSuppression() {
    this.didSuppressNative = true;
    document.body.classList.add("fomio-owned-notifications--replaced");
  }

  /**
   * Mirrors `user-notifications` route: only current user or admin may load another user's notifications.
   * @param {string} username
   */
  #canLoadNotificationsFor(username) {
    const u = this.currentUser;
    if (!u || !username) {
      return false;
    }
    return u.admin || u.username === username;
  }

  /**
   * @returns {{ shouldFetch: true, requestPath: string } | { shouldFetch: false } | null}
   */
  #notificationsInboxRequestContext() {
    const rawUrl = this.router.currentURL || "";
    const pathOnly = rawUrl.split("?")[0] || "";
    const inboxMatch = pathOnly.match(USER_NOTIFICATIONS_INBOX_PATH);
    if (!inboxMatch) {
      return null;
    }
    const username = inboxMatch[1];
    if (!this.#canLoadNotificationsFor(username)) {
      return { shouldFetch: false };
    }
    const queryString = rawUrl.includes("?")
      ? rawUrl.slice(rawUrl.indexOf("?") + 1)
      : "";
    const qp = new URLSearchParams(queryString);
    const filter = qp.get("filter");
    const params = new URLSearchParams();
    params.set("username", username);
    params.set("limit", String(NOTIFICATIONS_INDEX_LIMIT));
    if (filter === "read" || filter === "unread") {
      params.set("filter", filter);
    }
    return {
      shouldFetch: true,
      requestPath: `/notifications.json?${params.toString()}`,
    };
  }

  @action
  async dismissAll() {
    if (this.dismissing || !this.unreadCount) {
      return;
    }
    this.dismissing = true;
    try {
      await ajax("/notifications/mark-read.json", { method: "PUT" });
      this.items = this.items.map((n) => {
        if (n && !n.read) {
          return { ...n, read: true };
        }
        return n;
      });
    } catch {
      // Keep state if failed
    } finally {
      if (this.#alive) {
        this.dismissing = false;
      }
    }
  }

  @action
  syncFromRoute() {
    if (!this.enabled || !this.#alive) {
      return;
    }
    const ctx = this.#notificationsInboxRequestContext();
    if (!ctx) {
      return;
    }
    if (!ctx.shouldFetch) {
      this.loading = false;
      this.failed = false;
      this.items = [];
      this.nextPath = null;
      if (this.didSuppressNative) {
        document.body.classList.remove("fomio-owned-notifications--replaced");
        this.didSuppressNative = false;
      }
      return;
    }
    this.loadInitial(ctx.requestPath);
    setTimeout(() => this.extractPluginRows(), 100);
  }

  async loadInitial(requestPath) {
    const generation = ++this.#loadGeneration;
    this.loading = true;
    this.failed = false;
    this.items = [];
    this.nextPath = null;
    if (this.didSuppressNative) {
      document.body.classList.remove("fomio-owned-notifications--replaced");
      this.didSuppressNative = false;
    }

    try {
      const data = await ajax(requestPath);
      if (!this.#alive || generation !== this.#loadGeneration) {
        return;
      }
      const list = Array.isArray(data.notifications) ? data.notifications : [];
      this.items = list.filter((n) => n != null);
      this.nextPath = this.normalizeLoadMore(data.load_more_notifications);
      this.loading = false;
      this.applyNativeSuppression();
    } catch {
      if (!this.#alive || generation !== this.#loadGeneration) {
        return;
      }
      this.loading = false;
      this.failed = true;
    }
  }

  @action
  async loadMore() {
    if (!this.nextPath || this.loadingMore) {
      return;
    }
    this.loadingMore = true;
    try {
      const path = this.nextPath.startsWith("/")
        ? this.nextPath
        : `/${this.nextPath}`;
      const data = await ajax(path);
      if (!this.#alive) {
        return;
      }
      const more = Array.isArray(data.notifications)
        ? data.notifications.filter((n) => n != null)
        : [];
      this.items = [...this.items, ...more];
      this.nextPath = this.normalizeLoadMore(data.load_more_notifications);
    } catch {
      // Keep loaded items; user can retry load more.
    } finally {
      if (this.#alive) {
        this.loadingMore = false;
      }
    }
  }

  displayLabel(displayKey) {
    const key =
      displayKey && typeof displayKey === "string" && /^[a-z]+$/.test(displayKey)
        ? displayKey
        : "notification";
    return i18n(themePrefix(`me_owned_notifications.display.${key}`));
  }

  @action
  typeLabelFor(raw) {
    if (!raw) {
      return this.displayLabel("notification");
    }
    const internal = normalizeType(raw.notification_type);
    const category = displayCategory(internal);
    return this.displayLabel(category);
  }

  @action
  cardLabel(raw) {
    if (!raw) {
      return "";
    }
    const title = notificationTitle(raw);
    if (title) {
      return title;
    }
    const internal = normalizeType(raw.notification_type);
    const category = displayCategory(internal);
    return this.displayLabel(category);
  }

  @action
  cardMeta(raw) {
    if (!raw) {
      return "";
    }
    return notificationExcerpt(raw);
  }

  @action
  relativeTime(raw) {
    if (!raw) {
      return "";
    }
    return formatRelativeTime(raw.created_at);
  }

  @action
  cardHref(raw) {
    if (!raw) {
      return getURL("/");
    }
    return notificationHref(raw);
  }

  @action
  isUnread(raw) {
    return Boolean(raw && !raw.read);
  }

  <template>
    {{#if this.enabled}}
      {{#unless this.failed}}
        <section
          class="fomio-owned-notifications"
          data-fomio-owned-notifications="true"
          aria-label={{i18n (themePrefix "me_owned_notifications.list_label")}}
        >
          <header class="fomio-owned-notifications__header">
            <div class="fomio-owned-notifications__header-top">
              <h2 class="fomio-owned-notifications__heading">{{i18n
                  (themePrefix "me_owned_notifications.header_title")
                }}</h2>
              {{#if this.unreadCount}}
                <button
                  type="button"
                  class="fomio-owned-notifications__dismiss-all"
                  {{on "click" this.dismissAll}}
                  disabled={{this.dismissing}}
                  aria-label={{i18n "notifications.dismiss_all"}}
                >
                  {{icon "check"}}
                </button>
              {{/if}}
            </div>
            {{#if this.loading}}
              <p class="fomio-owned-notifications__summary">{{i18n
                  (themePrefix "me_owned_notifications.loading_summary")
                }}</p>
            {{else if this.hasItems}}
              {{#if this.unreadCount}}
                <p class="fomio-owned-notifications__summary">{{i18n
                    (themePrefix "me_owned_notifications.summary_unread")
                    count=this.unreadCount
                  }}</p>
                <p class="fomio-owned-notifications__tagline">{{i18n
                    (themePrefix "me_owned_notifications.tagline")
                  }}</p>
              {{else}}
                <p class="fomio-owned-notifications__summary">{{i18n
                    (themePrefix "me_owned_notifications.summary_caught_up")
                  }}</p>
              {{/if}}
            {{/if}}
          </header>

          <div class="fomio-owned-notifications__accordion" {{didInsert this.extractPluginRows}}>
            {{#each this.disclosureGroups as |g|}}
              <div class="fomio-owned-notifications-group {{if (eq this.openDisclosureGroupId g.id) 'is-expanded'}}">
                <button
                  id={{g.triggerId}}
                  type="button"
                  class="fomio-owned-notifications-group__header"
                  aria-expanded={{if (eq this.openDisclosureGroupId g.id) "true" "false"}}
                  aria-controls={{g.panelId}}
                  {{on "click" (fn this.toggleDisclosureGroup g.id)}}
                >
                  {{g.label}}
                  {{icon "chevron-down"}}
                </button>
                <div
                  id={{g.panelId}}
                  class="fomio-owned-notifications-group__panel"
                  role="region"
                  aria-labelledby={{g.triggerId}}
                  hidden={{if (eq this.openDisclosureGroupId g.id) false true}}
                >
                  {{#each g.rows as |row|}}
                    <a
                      href={{row.href}}
                      class="fomio-owned-notifications-group__link {{if row.isActive 'is-active'}}"
                      aria-current={{if row.isActive "page"}}
                    >
                      {{row.label}}
                    </a>
                  {{/each}}
                </div>
              </div>
            {{/each}}
          </div>


          {{#if this.loading}}
            <div
              class="fomio-owned-notifications__skeleton"
              aria-busy="true"
              aria-live="polite"
            >
              <span class="fomio-owned-notifications__sr-only">{{i18n
                  (themePrefix "me_owned_notifications.loading")
                }}</span>
              {{#each this.skeletonPlaceholders key="@index" as |row|}}
                <div class="fomio-owned-notifications__skeleton-card">
                  <div class="fomio-owned-notifications__skeleton-card-inner">
                    <div class="fomio-owned-notifications__skeleton-dot"></div>
                    <div class="fomio-owned-notifications__skeleton-body">
                      <div class="fomio-owned-notifications__skeleton-pill"></div>
                      <div class="fomio-owned-notifications__skeleton-line"></div>
                      <div
                        class="fomio-owned-notifications__skeleton-line fomio-owned-notifications__skeleton-line--short"
                      ></div>
                      <div class="fomio-owned-notifications__skeleton-meta"></div>
                    </div>
                  </div>
                </div>
              {{/each}}
            </div>
          {{else if (not this.hasItems)}}
            <div class="fomio-owned-notifications__empty">
              <p class="fomio-owned-notifications__empty-title">{{i18n
                  (themePrefix "me_owned_notifications.empty_title")
                }}</p>
              <p class="fomio-owned-notifications__empty-body">{{i18n
                  (themePrefix "me_owned_notifications.empty_body")
                }}</p>
            </div>
          {{else}}
            <div class="fomio-owned-notifications__groups">
              {{#each this.groupedNotificationSections key="key" as |section|}}
                <div
                  class="fomio-owned-notifications__group"
                  role="group"
                  aria-labelledby="fomio-notif-group-{{section.key}}"
                >
                  <h3
                    class="fomio-owned-notifications__group-title"
                    id="fomio-notif-group-{{section.key}}"
                  >{{section.label}}</h3>
                  <ul class="fomio-owned-notifications__list" role="list">
                    {{#each section.items key="id" as |item|}}
                      <li class="fomio-owned-notifications__item" role="listitem">
                        <a
                          class={{if
                            (this.isUnread item)
                            "fomio-owned-notifications__card fomio-owned-notifications__card--unread"
                            "fomio-owned-notifications__card"
                          }}
                          href={{this.cardHref item}}
                        >
                          {{#if (this.isUnread item)}}
                            <span
                              class="fomio-owned-notifications__unread-dot"
                              aria-hidden="true"
                            ></span>
                          {{else}}
                            <span
                              class="fomio-owned-notifications__read-spacer"
                              aria-hidden="true"
                            ></span>
                          {{/if}}
                          <span class="fomio-owned-notifications__card-main">
                            <span
                              class="fomio-owned-notifications__type"
                            >{{this.typeLabelFor item}}</span>
                            <span
                              class="fomio-owned-notifications__title"
                            >{{this.cardLabel item}}</span>
                            {{#if (this.cardMeta item)}}
                              <span
                                class="fomio-owned-notifications__excerpt"
                              >{{this.cardMeta item}}</span>
                            {{/if}}
                            <span class="fomio-owned-notifications__meta">
                              <time
                                class="fomio-owned-notifications__time"
                                datetime={{item.created_at}}
                              >{{this.relativeTime item}}</time>
                            </span>
                          </span>
                        </a>
                      </li>
                    {{/each}}
                  </ul>
                </div>
              {{/each}}
            </div>
          {{/if}}

          {{#if (and this.showLoadMore (not this.loading))}}
            <button
              type="button"
              class="fomio-owned-notifications__load-more"
              {{on "click" this.loadMore}}
              disabled={{this.loadingMore}}
            >
              {{#if this.loadingMore}}
                {{i18n (themePrefix "me_owned_notifications.load_more_pending")}}
              {{else}}
                {{i18n (themePrefix "me_owned_notifications.load_more")}}
              {{/if}}
            </button>
          {{/if}}
        </section>
      {{/unless}}
    {{/if}}
  </template>
}
