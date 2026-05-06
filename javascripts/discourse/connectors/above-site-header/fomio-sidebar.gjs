import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// Keep in sync with fomio-layout.gjs. Discourse themes cannot share modules
// across files, so this list is intentionally duplicated.
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

export default class FomioSidebar extends Component {
  @service router;
  @service currentUser;
  @service site;
  @service composer;

  // null = follow active Hub; set to a Hub ID to manually expand/collapse
  @tracked _expandedHubId = null;

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return !isAuthPath(this.currentPath);
  }

  // ── Active state getters ──────────────────────────────────────

  get isHomeActive() {
    const p = this.currentPath;
    return p === "/" || HOME_URL_PREFIXES.some((prefix) => p.startsWith(prefix));
  }

  get isHubsActive() {
    const p = this.currentPath;
    return p === "/categories" || p.startsWith("/c/");
  }

  get isBookmarksActive() {
    return this.currentPath.includes("bookmarks");
  }

  get isNotificationsActive() {
    return this.currentPath.startsWith("/notifications");
  }

  // ── Hub/Teret active detection ────────────────────────────────

  // Parses /c/:slug/:id (Hub) and /c/:hubSlug/:teretSlug/:teretId (Teret)
  // by checking whether the 3rd or 4th path segment is numeric.
  get activeHubId() {
    const p = this.currentPath;
    if (!p.startsWith("/c/")) return null;
    const parts = p.split("/").filter(Boolean); // ["c", slug, id?|teretSlug, teretId?]
    if (parts[2] && /^\d+$/.test(parts[2])) {
      return parseInt(parts[2], 10);
    }
    if (parts[3] && /^\d+$/.test(parts[3])) {
      const teretId = parseInt(parts[3], 10);
      const teret = (this.site.categories || []).find((c) => c.id === teretId);
      return teret?.parent_category_id ?? null;
    }
    return null;
  }

  get activeTeretId() {
    const p = this.currentPath;
    if (!p.startsWith("/c/")) return null;
    const parts = p.split("/").filter(Boolean);
    if (parts[3] && /^\d+$/.test(parts[3])) {
      return parseInt(parts[3], 10);
    }
    return null;
  }

  // Which Hub is currently expanded: manual choice wins, otherwise follow active Hub.
  get expandedHubId() {
    return this._expandedHubId !== null ? this._expandedHubId : this.activeHubId;
  }

  // ── Data getters ──────────────────────────────────────────────

  get hubsWithTerets() {
    const all = this.site.categories || [];
    return all
      .filter((c) => !c.parent_category_id)
      .slice(0, 10)
      .map((hub) => ({
        hub,
        terets: all.filter((c) => c.parent_category_id === hub.id),
      }));
  }

  get hasMoreHubs() {
    return (this.site.categories || []).filter((c) => !c.parent_category_id).length > 10;
  }

  get bookmarksUrl() {
    return this.currentUser
      ? `/u/${this.currentUser.username}/activity/bookmarks`
      : WEB_LOGIN_URL;
  }

  get profileUrl() {
    return this.currentUser
      ? `/u/${this.currentUser.username}/summary`
      : WEB_LOGIN_URL;
  }

  // ── i18n getters ─────────────────────────────────────────────

  get ariaLabel()          { return i18n(themePrefix("sidebar.aria_label")); }
  get searchLabel()        { return i18n(themePrefix("sidebar.search_label")); }
  get homeLabel()          { return i18n(themePrefix("sidebar.home")); }
  get hubsLabel()          { return i18n(themePrefix("sidebar.hubs")); }
  get bookmarksLabel()     { return i18n(themePrefix("sidebar.bookmarks")); }
  get createByteLabel()    { return i18n(themePrefix("sidebar.create_byte")); }
  get notificationsLabel() { return i18n(themePrefix("sidebar.notifications")); }
  get signInLabel()        { return i18n(themePrefix("sidebar.sign_in")); }
  get allHubsLabel()       { return i18n(themePrefix("sidebar.all_hubs")); }

  // ── Actions ──────────────────────────────────────────────────

  @action
  openNewByte() {
    if (this.currentUser) {
      this.composer.openNewTopic();
    } else {
      window.location.href = WEB_LOGIN_URL;
    }
  }

  @action
  toggleHub(hubId, e) {
    e.preventDefault();
    e.stopPropagation();
    this._expandedHubId = this._expandedHubId === hubId ? null : hubId;
  }

  <template>
    {{#if this.shouldRender}}
      <nav class="fomio-sidebar" aria-label={{this.ariaLabel}}>

        {{! ── Zone A — Top (logo + search) ──────────────── }}
        <div class="fomio-sidebar__zone fomio-sidebar__zone--top">
          <a href="/latest" class="fomio-sidebar__wordmark" aria-label="Fomio">
            <span class="fomio-sidebar__wordmark-text">Fomio</span>
          </a>

          <a href="/search" class="fomio-sidebar__search-trigger" aria-label={{this.searchLabel}} title={{this.searchLabel}}>
            <span class="fomio-sidebar__icon">{{icon "magnifying-glass"}}</span>
            <span class="fomio-sidebar__item-label">{{this.searchLabel}}</span>
          </a>
        </div>

        {{! ── Zone B — Core navigation ───────────────────── }}
        <div class="fomio-sidebar__zone fomio-sidebar__zone--core">
          <a
            href="/latest"
            class="fomio-sidebar__item {{if this.isHomeActive 'is-active'}}"
            aria-current={{if this.isHomeActive "page"}}
            title={{this.homeLabel}}
          >
            <span class="fomio-sidebar__icon">{{icon "house"}}</span>
            <span class="fomio-sidebar__item-label">{{this.homeLabel}}</span>
          </a>

          {{! ── Hub tree ── }}
          <div class="fomio-sidebar__section">
            <a
              href="/categories"
              class="fomio-sidebar__item {{if this.isHubsActive 'is-active'}}"
              aria-current={{if this.isHubsActive "page"}}
              title={{this.hubsLabel}}
            >
              <span class="fomio-sidebar__icon">{{icon "compass"}}</span>
              <span class="fomio-sidebar__item-label">{{this.hubsLabel}}</span>
            </a>

            <ul class="fomio-sidebar__hub-list" aria-label={{this.hubsLabel}}>
              {{#each this.hubsWithTerets as |entry|}}
                {{#let entry.hub entry.terets as |hub terets|}}
                  <li class="fomio-sidebar__hub-item">

                    {{! Hub row: name navigates, chevron toggles }}
                    <div class="fomio-sidebar__hub-row {{if (eq this.activeHubId hub.id) 'is-active'}}">
                      <a
                        href="/c/{{hub.slug}}/{{hub.id}}"
                        class="fomio-sidebar__hub-link"
                        aria-current={{if (eq this.activeHubId hub.id) "page"}}
                      >
                        <span
                          class="fomio-sidebar__hub-dot"
                          style="background: #{{hub.color}}"
                          aria-hidden="true"
                        ></span>
                        <span class="fomio-sidebar__hub-name">{{hub.name}}</span>
                      </a>

                      {{#if terets.length}}
                        <button
                          type="button"
                          class="fomio-sidebar__hub-chevron {{if (eq this.expandedHubId hub.id) 'is-open'}}"
                          aria-expanded={{if (eq this.expandedHubId hub.id) "true" "false"}}
                          aria-label="{{hub.name}} terets"
                          {{on "click" (fn this.toggleHub hub.id)}}
                        >
                          {{icon "angle-right"}}
                        </button>
                      {{/if}}
                    </div>

                    {{! Teret sub-list }}
                    {{#if (eq this.expandedHubId hub.id)}}
                      <ul class="fomio-sidebar__teret-list">
                        {{#each terets as |teret|}}
                          <li>
                            <a
                              href="/c/{{hub.slug}}/{{teret.slug}}/{{teret.id}}"
                              class="fomio-sidebar__teret-link {{if (eq this.activeTeretId teret.id) 'is-active'}}"
                              aria-current={{if (eq this.activeTeretId teret.id) "page"}}
                            >
                              <span class="fomio-sidebar__teret-name">{{teret.name}}</span>
                            </a>
                          </li>
                        {{/each}}
                      </ul>
                    {{/if}}

                  </li>
                {{/let}}
              {{/each}}

              {{#if this.hasMoreHubs}}
                <li>
                  <a href="/categories" class="fomio-sidebar__hub-more">
                    {{this.allHubsLabel}}
                  </a>
                </li>
              {{/if}}
            </ul>
          </div>

          {{#if this.currentUser}}
            <a
              href={{this.bookmarksUrl}}
              class="fomio-sidebar__item {{if this.isBookmarksActive 'is-active'}}"
              aria-current={{if this.isBookmarksActive "page"}}
              title={{this.bookmarksLabel}}
            >
              <span class="fomio-sidebar__icon">{{icon "bookmark"}}</span>
              <span class="fomio-sidebar__item-label">{{this.bookmarksLabel}}</span>
            </a>
          {{/if}}

          <button
            type="button"
            class="fomio-sidebar__create-btn"
            title={{this.createByteLabel}}
            {{on "click" this.openNewByte}}
          >
            <span class="fomio-sidebar__icon">{{icon "pen-to-square"}}</span>
            <span>{{this.createByteLabel}}</span>
          </button>
        </div>

        {{! ── Zone C — Bottom (sticky) ───────────────────── }}
        <div class="fomio-sidebar__zone fomio-sidebar__zone--bottom">
          {{#if this.currentUser}}
            <a
              href="/notifications"
              class="fomio-sidebar__item {{if this.isNotificationsActive 'is-active'}}"
              aria-current={{if this.isNotificationsActive "page"}}
              title={{this.notificationsLabel}}
            >
              <span class="fomio-sidebar__icon">{{icon "bell"}}</span>
              <span class="fomio-sidebar__item-label">{{this.notificationsLabel}}</span>
            </a>

            <a href={{this.profileUrl}} class="fomio-sidebar__item fomio-sidebar__item--profile">
              <span class="fomio-sidebar__icon">{{icon "user"}}</span>
              <span class="fomio-sidebar__item-label">{{this.currentUser.username}}</span>
            </a>
          {{else}}
            <a href={{this.profileUrl}} class="fomio-sidebar__item">
              <span class="fomio-sidebar__icon">{{icon "user"}}</span>
              <span class="fomio-sidebar__item-label">{{this.signInLabel}}</span>
            </a>
          {{/if}}
        </div>

      </nav>
    {{/if}}
  </template>
}
