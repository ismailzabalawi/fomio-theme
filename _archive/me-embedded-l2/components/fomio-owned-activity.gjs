import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import icon from "discourse/helpers/d-icon";
import { themePrefix } from "virtual:theme";

function startOfLocalDayMs(d) {
  const x = new Date(d);
  return new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
}

function formatRelativeTime(iso1, iso2) {
  const iso = iso1 || iso2;
  if (!iso) return "";
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return "";
  const diffSec = Math.round((then - Date.now()) / 1000);
  const abs = Math.abs(diffSec);
  const rtf = new Intl.RelativeTimeFormat(undefined, { numeric: "auto" });
  if (abs < 45) return rtf.format(Math.round(diffSec / 60), "minute");
  if (abs < 3600) return rtf.format(Math.round(diffSec / 60), "minute");
  if (abs < 86400) return rtf.format(Math.round(diffSec / 3600), "hour");
  if (abs < 604800) return rtf.format(Math.round(diffSec / 86400), "day");
  return rtf.format(Math.round(diffSec / 604800), "week");
}

export default class FomioOwnedActivity extends Component {
  #alive = true;
  #loadGeneration = 0;

  @service router;
  @service currentUser;
  @service siteSettings;

  @tracked loading = true;
  @tracked loadingMore = false;
  @tracked failed = false;
  @tracked items = [];
  @tracked nextCursor = null;
  @tracked currentFilter = "all";

  didSuppressNative = false;

  get enabled() {
    return this.siteSettings.fomio_owned_me_activity_enabled;
  }

  get username() {
    const rawUrl = this.router.currentURL || "";
    const m = /^\/u\/([^/]+)\/activity/.exec(rawUrl.split("?")[0]);
    if (m) {
      return decodeURIComponent(m[1]);
    }
    return this.currentUser?.username;
  }

  get isCurrentUser() {
    return this.username === this.currentUser?.username;
  }

  get groupedItems() {
    if (!this.items.length) return [];
    
    const now = new Date();
    const todayStart = startOfLocalDayMs(now);
    const yesterdayStart = todayStart - 86400000;

    const today = [];
    const yesterday = [];
    const earlier = [];

    for (const item of this.items) {
      const ts = new Date(item.updated_at || item.created_at).getTime();
      if (ts >= todayStart) {
        today.push(item);
      } else if (ts >= yesterdayStart) {
        yesterday.push(item);
      } else {
        earlier.push(item);
      }
    }

    const groups = [];
    if (today.length) groups.push({ label: i18n(themePrefix("me_owned_notifications.group_today")), items: today });
    if (yesterday.length) groups.push({ label: i18n(themePrefix("me_owned_notifications.group_yesterday")), items: yesterday });
    if (earlier.length) groups.push({ label: i18n(themePrefix("me_owned_notifications.group_earlier")), items: earlier });
    
    return groups;
  }

  get hasItems() {
    return this.items.length > 0;
  }

  get filterGroups() {
    return [
      {
        id: "recent",
        label: i18n(themePrefix("me_owned_activity.group_recent")),
        rows: [
          { id: "all", label: i18n(themePrefix("me_owned_activity.filter_all")) }
        ]
      },
      {
        id: "publishing",
        label: i18n(themePrefix("me_owned_activity.group_publishing")),
        rows: [
          { id: "topics", label: i18n(themePrefix("me_owned_activity.filter_topics")) },
          { id: "replies", label: i18n(themePrefix("me_owned_activity.filter_replies")) }
        ]
      },
      {
        id: "reading",
        label: i18n(themePrefix("me_owned_activity.group_reading")),
        rows: [
          { id: "bookmarks", label: i18n(themePrefix("me_owned_activity.filter_bookmarks")) }
        ]
      },
      {
        id: "reactions",
        label: i18n(themePrefix("me_owned_activity.group_reactions")),
        rows: [
          { id: "likes_given", label: i18n(themePrefix("me_owned_activity.filter_likes_given")) }
        ]
      }
    ];
  }

  constructor() {
    super(...arguments);
    if (!this.enabled) return;
    
    // Attempt to map route to filter
    const route = this.router.currentRouteName;
    if (route === "userActivity.topics") this.currentFilter = "topics";
    else if (route === "userActivity.replies") this.currentFilter = "replies";
    else if (route === "userActivity.likesGiven") this.currentFilter = "likes_given";
    else if (route === "userActivity.bookmarks") this.currentFilter = "bookmarks";
    else this.currentFilter = "all";

    this.router.on("routeDidChange", this.#onRouteDidChange);
    this.loadInitial();
  }

  willDestroy() {
    super.willDestroy();
    this.#alive = false;
    this.router.off("routeDidChange", this.#onRouteDidChange);
    if (this.didSuppressNative) {
      document.body.classList.remove("fomio-owned-activity--replaced");
    }
  }

  #onRouteDidChange = () => {
    if (!this.enabled) return;
    const route = this.router.currentRouteName;
    if (!route || !route.startsWith("userActivity")) {
      return;
    }
    
    let nextFilter = "all";
    if (route === "userActivity.topics") nextFilter = "topics";
    else if (route === "userActivity.replies") nextFilter = "replies";
    else if (route === "userActivity.likesGiven") nextFilter = "likes_given";
    else if (route === "userActivity.bookmarks") nextFilter = "bookmarks";
    else if (route === "userActivity.index") nextFilter = "all";
    else {
      // Unhandled route (e.g. drafts, read). We should probably un-suppress if we don't support it.
      if (this.didSuppressNative) {
        document.body.classList.remove("fomio-owned-activity--replaced");
        this.didSuppressNative = false;
      }
      return;
    }

    if (this.currentFilter !== nextFilter) {
      this.currentFilter = nextFilter;
      this.loadInitial();
    }
  };

  applyNativeSuppression() {
    if (!this.didSuppressNative && this.#alive) {
      this.didSuppressNative = true;
      document.body.classList.add("fomio-owned-activity--replaced");
    }
  }

  async loadInitial() {
    const generation = ++this.#loadGeneration;
    this.loading = true;
    this.failed = false;
    this.items = [];
    this.nextCursor = null;

    if (this.didSuppressNative) {
      document.body.classList.remove("fomio-owned-activity--replaced");
      this.didSuppressNative = false;
    }

    try {
      const username = this.username;
      if (!username) {
        throw new Error("No username");
      }
      
      const url = `/fomio/me/activity.json?username=${encodeURIComponent(username)}&filter=${this.currentFilter}&limit=20`;
      const data = await ajax(url);
      
      if (!this.#alive || generation !== this.#loadGeneration) {
        return;
      }
      
      this.items = Array.isArray(data.items) ? data.items : [];
      this.nextCursor = data.next_cursor;
      this.loading = false;
      this.applyNativeSuppression();
    } catch (e) {
      if (!this.#alive || generation !== this.#loadGeneration) {
        return;
      }
      this.loading = false;
      this.failed = true;
    }
  }

  @action
  async loadMore() {
    if (!this.nextCursor || this.loadingMore) return;
    this.loadingMore = true;

    try {
      const username = this.username;
      const url = `/fomio/me/activity.json?username=${encodeURIComponent(username)}&filter=${this.currentFilter}&limit=20&cursor=${encodeURIComponent(this.nextCursor)}`;
      const data = await ajax(url);
      
      if (!this.#alive) return;
      
      const newItems = Array.isArray(data.items) ? data.items : [];
      this.items = [...this.items, ...newItems];
      this.nextCursor = data.next_cursor;
    } catch {
      // keep existing state
    } finally {
      if (this.#alive) {
        this.loadingMore = false;
      }
    }
  }

  @action
  setFilter(filterId, event) {
    event.preventDefault();
    this.currentFilter = filterId;
    
    // Sync the route conceptually if we want URL parity
    const username = this.username;
    if (filterId === "all") this.router.transitionTo("userActivity.index", username);
    else if (filterId === "topics") this.router.transitionTo("userActivity.topics", username);
    else if (filterId === "replies") this.router.transitionTo("userActivity.replies", username);
    else if (filterId === "likes_given") this.router.transitionTo("userActivity.likesGiven", username);
    else if (filterId === "bookmarks") this.router.transitionTo("userActivity.bookmarks", username);
    else this.loadInitial();
  }

  kindLabel(kind) {
    if (kind === "topic") return i18n(themePrefix("me_owned_activity.kind_topic"));
    if (kind === "reply") return i18n(themePrefix("me_owned_activity.kind_reply"));
    if (kind === "like_given") return i18n(themePrefix("me_owned_activity.kind_reaction"));
    if (kind === "bookmark") return i18n(themePrefix("me_owned_activity.kind_saved"));
    return i18n(themePrefix("me_owned_activity.kind_activity"));
  }

  kindIcon(kind) {
    if (kind === "topic") return "layer-group";
    if (kind === "reply") return "reply";
    if (kind === "like_given") return "heart";
    if (kind === "bookmark") return "bookmark";
    return "clock-rotate-left";
  }

  filterLinkClass(rowId) {
    const base = "fomio-owned-activity-filter-group__link";
    return this.currentFilter === rowId ? `${base} is-active` : base;
  }

  itemRelativeTime(item) {
    return formatRelativeTime(item.updated_at, item.created_at);
  }

  <template>
    {{#if this.enabled}}
      {{#unless this.failed}}
        <section class="fomio-owned-activity">
          <header class="fomio-owned-activity__header">
            <h2 class="fomio-owned-activity__heading">{{i18n (themePrefix "me_owned_activity.header_title")}}</h2>
            <p class="fomio-owned-activity__tagline">{{i18n (themePrefix "me_owned_activity.tagline")}}</p>
          </header>

          <div class="fomio-owned-activity__layout">
            <nav class="fomio-owned-activity__sidebar">
              {{#each this.filterGroups as |group|}}
                <div class="fomio-owned-activity-filter-group">
                  <h3 class="fomio-owned-activity-filter-group__heading">{{group.label}}</h3>
                  <ul class="fomio-owned-activity-filter-group__list">
                    {{#each group.rows as |row|}}
                      <li>
                        <a
                          href="#"
                          class={{this.filterLinkClass row.id}}
                          {{on "click" (fn this.setFilter row.id)}}
                        >
                          {{row.label}}
                        </a>
                      </li>
                    {{/each}}
                  </ul>
                </div>
              {{/each}}
            </nav>

            <div class="fomio-owned-activity__content">
              {{#if this.loading}}
                <div class="fomio-owned-activity__skeleton" aria-busy="true">
                  <span class="fomio-owned-activity__sr-only">{{i18n (themePrefix "me_owned_activity.loading")}}</span>
                </div>
              {{else if this.hasItems}}
                <div class="fomio-owned-activity__list">
                  {{#each this.groupedItems as |group|}}
                    <div class="fomio-owned-activity-time-group">
                      <h4 class="fomio-owned-activity-time-group__heading">{{group.label}}</h4>
                      {{#each group.items as |item|}}
                        <a href={{item.url}} class="fomio-owned-activity-card">
                          <div class="fomio-owned-activity-card__header">
                            <span class="fomio-owned-activity-card__kind">
                              {{icon (this.kindIcon item.kind)}}
                              {{this.kindLabel item.kind}}
                            </span>
                            <span class="fomio-owned-activity-card__time">
                              {{this.itemRelativeTime item}}
                            </span>
                          </div>
                          <div class="fomio-owned-activity-card__body">
                            <h3 class="fomio-owned-activity-card__title">{{item.title}}</h3>
                            {{#if item.excerpt}}
                              <p class="fomio-owned-activity-card__excerpt">{{item.excerpt}}</p>
                            {{/if}}
                          </div>
                          {{#if item.meta}}
                            <div class="fomio-owned-activity-card__footer">
                              {{#if item.meta.reply_count}}
                                <span class="fomio-owned-activity-card__meta-item">
                                  {{icon "reply"}} {{item.meta.reply_count}}
                                </span>
                              {{/if}}
                              {{#if item.meta.like_count}}
                                <span class="fomio-owned-activity-card__meta-item">
                                  {{icon "heart"}} {{item.meta.like_count}}
                                </span>
                              {{/if}}
                            </div>
                          {{/if}}
                        </a>
                      {{/each}}
                    </div>
                  {{/each}}
                </div>
                
                {{#if this.nextCursor}}
                  <button
                    type="button"
                    class="fomio-owned-activity__load-more"
                    disabled={{this.loadingMore}}
                    {{on "click" this.loadMore}}
                  >
                    {{#if this.loadingMore}}
                      {{i18n (themePrefix "me_owned_activity.loading_more")}}
                    {{else}}
                      {{i18n (themePrefix "me_owned_activity.load_more")}}
                    {{/if}}
                  </button>
                {{/if}}
              {{else}}
                <div class="fomio-owned-activity__empty">
                  <p>{{i18n (themePrefix "me_owned_activity.empty")}}</p>
                </div>
              {{/if}}
            </div>
          </div>
        </section>
      {{/unless}}
    {{/if}}
  </template>
}
