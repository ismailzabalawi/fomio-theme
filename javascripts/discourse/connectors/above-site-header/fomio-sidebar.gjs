import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
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

  // ── Data getters ──────────────────────────────────────────────

  get topLevelHubs() {
    return (this.site.categories || [])
      .filter((c) => !c.parent_category_id)
      .slice(0, 10);
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

  get ariaLabel() { return i18n(themePrefix("sidebar.aria_label")); }
  get searchLabel() { return i18n(themePrefix("sidebar.search_label")); }
  get homeLabel() { return i18n(themePrefix("sidebar.home")); }
  get hubsLabel() { return i18n(themePrefix("sidebar.hubs")); }
  get bookmarksLabel() { return i18n(themePrefix("sidebar.bookmarks")); }
  get createByteLabel() { return i18n(themePrefix("sidebar.create_byte")); }
  get notificationsLabel() { return i18n(themePrefix("sidebar.notifications")); }
  get signInLabel() { return i18n(themePrefix("sidebar.sign_in")); }

  // ── Actions ──────────────────────────────────────────────────

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

          <a
            href="/categories"
            class="fomio-sidebar__item {{if this.isHubsActive 'is-active'}}"
            aria-current={{if this.isHubsActive "page"}}
            title={{this.hubsLabel}}
          >
            <span class="fomio-sidebar__icon">{{icon "compass"}}</span>
            <span class="fomio-sidebar__item-label">{{this.hubsLabel}}</span>
          </a>

          {{#if this.isHubsActive}}
            <ul class="fomio-sidebar__hub-list" aria-label={{this.hubsLabel}}>
              {{#each this.topLevelHubs as |hub|}}
                <li>
                  <a
                    href="/c/{{hub.slug}}/{{hub.id}}"
                    class="fomio-sidebar__hub-link"
                  >
                    <span
                      class="fomio-sidebar__hub-dot"
                      style="background: #{{hub.color}}"
                      aria-hidden="true"
                    ></span>
                    <span class="fomio-sidebar__hub-name">{{hub.name}}</span>
                  </a>
                </li>
              {{/each}}
            </ul>
          {{/if}}

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
