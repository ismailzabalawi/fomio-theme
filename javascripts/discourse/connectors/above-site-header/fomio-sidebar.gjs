import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";
import { buildFomioHubCatalog } from "../../lib/fomio-hub-catalog";
import {
  openDesktopSearchPalette,
  subscribeDesktopSearchPalette,
} from "../../lib/fomio-desktop-search-palette";
import {
  FOMIO_NOTIFICATIONS_MENU_STATE_EVENT,
  openFomioNotificationsMenu,
} from "../../lib/fomio-notifications-menu";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";
import {
  bookmarksPathForUser,
  isFomioShellPath,
  isOwnBookmarksPath,
  isOwnNotificationsPath,
  isOwnProfileShellPath,
  profileSummaryPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import { PENDING_RAIL_OVERLAY_KEY } from "../../lib/fomio-rail-overlay-state";

const WEB_LOGIN_URL = "/login?fomio_web=1";
const MASTER_CONTEXTS = ["home", "hubs", "bookmarks", "notifications", "profile"];

export default class FomioSidebar extends Component {
  @service router;
  @service currentUser;
  @service site;
  @service composer;
  @service session;
  @service siteSettings;
  @service interfaceColor;

  // null = follow active Hub; set to a Hub ID to manually expand/collapse
  @tracked _expandedHubId = null;
  @tracked isTouchSurface = false;
  @tracked isSearchSheetOpen = false;
  @tracked notificationsMenuOpen = false;
  #unsubscribeTouchShell = null;
  #unsubscribeSearchPalette = null;
  #notificationsMenuStateHandler = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouchShell = subscribeFomioTouchShell((isTouchSurface) => {
      this.isTouchSurface = isTouchSurface;
    });
    this.#unsubscribeSearchPalette = subscribeDesktopSearchPalette((isOpen) => {
      this.isSearchSheetOpen = isOpen;
    });
    this.#notificationsMenuStateHandler = (event) => {
      this.notificationsMenuOpen = Boolean(event?.detail?.open);
    };
    window.addEventListener(
      FOMIO_NOTIFICATIONS_MENU_STATE_EVENT,
      this.#notificationsMenuStateHandler
    );
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#unsubscribeTouchShell?.();
    this.#unsubscribeSearchPalette?.();
    window.removeEventListener(
      FOMIO_NOTIFICATIONS_MENU_STATE_EVENT,
      this.#notificationsMenuStateHandler
    );
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get isRailSurface() {
    if (typeof document === "undefined") {
      return false;
    }

    return document.body?.classList.contains("fomio-surface-rail");
  }

  get isCompactDesktopSurface() {
    if (typeof document === "undefined") {
      return false;
    }

    return document.body?.classList.contains("fomio-surface-compact-desktop");
  }

  get shouldRender() {
    return isFomioShellPath(this.currentPath) && !this.isTouchSurface;
  }

  // ── Master context skeleton (Build Slice 3A) ───────────────────
  // Sidebar is the master layer. For this slice we map current routing
  // to a lightweight master context model without changing route behavior.
  get activeMasterContext() {
    if (this.isHubsActive) {
      return "hubs";
    }
    if (this.isBookmarksActive) {
      return "bookmarks";
    }
    if (this.isNotificationsActive) {
      return "notifications";
    }
    if (this.isProfileActive) {
      return "profile";
    }
    return "home";
  }

  get masterContexts() {
    return MASTER_CONTEXTS;
  }

  // ── Active state getters ──────────────────────────────────────

  get isLatestActive() {
    const p = this.currentPath;
    return p === "/" || p.startsWith("/latest");
  }

  get isHotActive() {
    return this.currentPath.startsWith("/hot");
  }

  get isHubsActive() {
    const p = this.currentPath;
    return p === "/categories" || p.startsWith("/c/");
  }

  get isBookmarksActive() {
    return isOwnBookmarksPath(this.currentPath, this.currentUser);
  }

  get isNotificationsActive() {
    return (
      isOwnNotificationsPath(this.currentPath, this.currentUser) ||
      this.notificationsMenuOpen
    );
  }

  get isProfileActive() {
    return isOwnProfileShellPath(this.currentPath, this.currentUser);
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
      const teret = this.hubCatalog.categories.find((category) => category.id === teretId);
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
    return this.hubCatalog.topLevelHubs.map((hub) => ({
      hub,
      terets: this.hubCatalog.categories.filter(
        (category) => category.parent_category_id === hub.id
      ),
    }));
  }

  get hasMoreHubs() {
    return this.hubCatalog.hasMoreHubs;
  }

  get hubCatalog() {
    return buildFomioHubCatalog([
      this.site?.categories,
      this.site?.categoryList?.categories,
      this.site?.categoriesList,
      this.site?.site?.categories,
      this.args?.outletArgs?.site?.categories,
      this.args?.outletArgs?.categoryList?.categories,
    ]);
  }

  get isRailOrTouchSurface() {
    if (typeof document === "undefined") {
      return false;
    }
    const classes = document.body?.classList;
    return (
      classes?.contains("fomio-surface-rail") ||
      classes?.contains("fomio-surface-touch")
    );
  }

  get isMasterPaneActive() {
    if (typeof document === "undefined") {
      return false;
    }
    const classes = document.body?.classList;
    const isExpandedOrCompact =
      classes?.contains("fomio-surface-expanded") ||
      classes?.contains("fomio-surface-compact-desktop");
    return (
      this.activeMasterContext === "hubs" &&
      Boolean(isExpandedOrCompact) &&
      classes?.contains("fomio-sidebar-active") &&
      !classes?.contains("fomio-auth-mode")
    );
  }

  // Secondary Hub list is intentionally desktop-only for this skeleton.
  // Rail stays symbolic and touch stays bottom-nav driven.
  get showHubsSecondaryList() {
    return (
      this.activeMasterContext === "hubs" &&
      !this.isMasterPaneActive &&
      !this.isRailOrTouchSurface &&
      this.hubsWithTerets.length > 0
    );
  }

  get bookmarksUrl() {
    return bookmarksPathForUser(this.currentUser) ?? WEB_LOGIN_URL;
  }

  get profileUrl() {
    return profileSummaryPathForUser(this.currentUser) ?? WEB_LOGIN_URL;
  }

  // ── i18n getters ─────────────────────────────────────────────

  get ariaLabel()          { return i18n(themePrefix("sidebar.aria_label")); }
  get searchLabel()        { return i18n(themePrefix("sidebar.search_label")); }
  get latestLabel()        { return i18n(themePrefix("sidebar.latest")); }
  get hotLabel()           { return i18n(themePrefix("sidebar.hot")); }
  get hubsLabel()          { return i18n(themePrefix("sidebar.hubs")); }
  get bookmarksLabel()     { return i18n(themePrefix("sidebar.bookmarks")); }
  get createByteLabel()    { return i18n(themePrefix("sidebar.create_byte")); }
  get notificationsLabel() { return i18n(themePrefix("sidebar.notifications")); }
  get notificationsBadge() {
    const count = this.currentUser?.all_unread_notifications_count;
    if (!count || count <= 0) {
      return null;
    }

    return count > 99 ? "99+" : String(count);
  }
  get signInLabel()        { return i18n(themePrefix("sidebar.sign_in")); }
  get allHubsLabel()       { return i18n(themePrefix("sidebar.all_hubs")); }
  get closeMenuLabel()     { return i18n(themePrefix("sidebar.close_menu")); }
  get searchShortcutLabel() {
    return "/";
  }

  get darkMediaQuery() {
    if (this.interfaceColor.darkModeForced) {
      return "all";
    }

    if (this.interfaceColor.lightModeForced) {
      return "none";
    }

    return "(prefers-color-scheme: dark)";
  }

  get logoTitle() {
    return this.siteSettings.title;
  }

  get logoUrl() {
    return this.logoResolver("logo");
  }

  get logoUrlDark() {
    return this.logoResolver("logo", { dark: this.session.darkModeAvailable });
  }

  get logoSmallUrl() {
    return this.logoResolver("logo_small");
  }

  get logoSmallUrlDark() {
    return this.logoResolver("logo_small", {
      dark: this.session.darkModeAvailable,
    });
  }

  get mobileLogoUrl() {
    return this.logoResolver("mobile_logo");
  }

  get mobileLogoUrlDark() {
    return this.logoResolver("mobile_logo", {
      dark: this.session.darkModeAvailable,
    });
  }

  get showCompactLogo() {
    return this.isRailSurface || this.isCompactDesktopSurface;
  }

  get currentLogoUrl() {
    if (!this.showCompactLogo) {
      return this.logoUrl;
    }

    return this.logoSmallUrl || this.mobileLogoUrl || this.logoUrl;
  }

  get currentLogoUrlDark() {
    if (!this.showCompactLogo) {
      return this.logoUrlDark;
    }

    return this.logoSmallUrlDark || this.mobileLogoUrlDark || this.logoUrlDark;
  }

  get currentLogoClass() {
    return this.showCompactLogo
      ? "fomio-sidebar__logo-image fomio-sidebar__logo-image--small"
      : "fomio-sidebar__logo-image fomio-sidebar__logo-image--full";
  }

  get hasCurrentLogo() {
    return Boolean(this.currentLogoUrl);
  }

  get hasDistinctDarkCurrentLogo() {
    return Boolean(
      this.currentLogoUrlDark && this.currentLogoUrlDark !== this.currentLogoUrl
    );
  }

  get showTextLogoFallback() {
    return !this.showCompactLogo && !this.hasCurrentLogo;
  }

  get showCompactIconFallback() {
    return this.showCompactLogo && !this.hasCurrentLogo;
  }

  logoResolver(name, opts = {}) {
    let url;

    if (opts.dark) {
      url = this.siteSettings[`site_${name}_dark_url`];
    } else if (this.session.defaultColorSchemeIsDark) {
      url =
        this.siteSettings[`site_${name}_dark_url`] ||
        this.siteSettings[`site_${name}_url`] ||
        "";
    } else {
      url = this.siteSettings[`site_${name}_url`] || "";
    }

    return url;
  }

  // ── Actions ──────────────────────────────────────────────────

  @action
  openNewByte() {
    document.body.classList.remove("fomio-mobile-sidebar-open");
    if (this.currentUser) {
      try {
        this.composer.openNewTopic();
      } catch (e) {
        console.warn("[Fomio] composer.openNewTopic failed from sidebar", e);
      }
    } else {
      redirectToLoginWithIntent("create_byte", this.currentPath);
    }
  }

  @action
  toggleHub(hubId, e) {
    e.preventDefault();
    e.stopPropagation();
    this._expandedHubId = this._expandedHubId === hubId ? null : hubId;
  }

  // Close the mobile sidebar when a navigation link inside it is tapped.
  @action
  onNavClick(e) {
    if (e.target.closest("a[href]")) {
      document.body.classList.remove("fomio-mobile-sidebar-open");
      document.body.classList.remove("fomio-master-pane-rail-open");
    }
  }

  // Close button and overlay tap handler.
  @action
  closeMobile() {
    document.body.classList.remove("fomio-mobile-sidebar-open");
  }

  @action
  toggleSearchSheet(event) {
    event?.preventDefault();
    event?.stopPropagation();
    openDesktopSearchPalette();
  }

  @action
  toggleRailOverlay(context, e) {
    if (typeof document === "undefined") {
      return;
    }

    const classes = document.body?.classList;
    const canOpenRailOverlay =
      classes?.contains("fomio-surface-rail") &&
      classes?.contains("fomio-sidebar-active") &&
      !classes?.contains("fomio-auth-mode");

    if (!canOpenRailOverlay) {
      return;
    }

    if (typeof window !== "undefined" && window.sessionStorage) {
      window.sessionStorage.setItem(PENDING_RAIL_OVERLAY_KEY, context);
    }

    e?.preventDefault();
    e?.stopPropagation();
    window.dispatchEvent(
      new CustomEvent(
        this.activeMasterContext === context
          ? "fomio:master-pane:toggle"
          : "fomio:master-pane:open",
        {
          detail: { context },
        }
      )
    );
  }

  @action
  onHubsActivate(e) {
    this.toggleRailOverlay("hubs", e);
  }

  @action
  onBookmarksActivate(e) {
    this.toggleRailOverlay("bookmarks", e);
  }

  @action
  onNotificationsActivate(e) {
    e?.preventDefault();
    e?.stopPropagation();

    if (!this.currentUser) {
      redirectToLoginWithIntent("view_profile", this.currentPath);
      return;
    }

    document.body.classList.remove("fomio-mobile-sidebar-open");
    document.body.classList.remove("fomio-master-pane-rail-open");
    openFomioNotificationsMenu("desktop", e?.currentTarget?.getBoundingClientRect?.());
  }

  @action
  onProfileActivate(e) {
    this.toggleRailOverlay("profile", e);
  }

  <template>
    {{#if this.shouldRender}}

      {{! Backdrop — covers page content on mobile when sidebar is open.
          Click closes the sidebar. Hidden on desktop via CSS. }}
      <div
        class="fomio-sidebar-backdrop"
        aria-hidden="true"
        {{on "click" this.closeMobile}}
      ></div>

      <nav
        class="fomio-sidebar"
        data-fomio-master-context={{this.activeMasterContext}}
        aria-label={{this.ariaLabel}}
        {{on "click" this.onNavClick}}
      >

        {{! ── Mobile close button — hidden on desktop via CSS ──────── }}
        <button
          type="button"
          class="fomio-sidebar__mobile-close"
          aria-label={{this.closeMenuLabel}}
          {{on "click" this.closeMobile}}
        >
          {{icon "xmark"}}
        </button>

        {{! ── Zone A — Top (logo + search) ──────────────── }}
        <div class="fomio-sidebar__zone fomio-sidebar__zone--top">
          <a
            href="/latest"
            class="fomio-sidebar__wordmark"
            aria-label={{this.logoTitle}}
          >
            {{#if this.hasCurrentLogo}}
              {{#if this.hasDistinctDarkCurrentLogo}}
                <picture class="fomio-sidebar__logo-picture">
                  <source
                    srcset={{getURL this.currentLogoUrlDark}}
                    media={{this.darkMediaQuery}}
                  />
                  <img
                    class={{this.currentLogoClass}}
                    src={{getURL this.currentLogoUrl}}
                    alt={{this.logoTitle}}
                  />
                </picture>
              {{else}}
                <img
                  class={{this.currentLogoClass}}
                  src={{getURL this.currentLogoUrl}}
                  alt={{this.logoTitle}}
                />
              {{/if}}
            {{else if this.showCompactIconFallback}}
              <span class="fomio-sidebar__wordmark-fallback-icon" aria-hidden="true">
                {{icon "house"}}
              </span>
            {{else if this.showTextLogoFallback}}
              <span class="fomio-sidebar__wordmark-text">{{this.logoTitle}}</span>
            {{/if}}
          </a>

          {{#if this.isRailSurface}}
            <button
              type="button"
              class="fomio-sidebar__search-trigger"
              aria-label={{this.searchLabel}}
              title={{this.searchLabel}}
              aria-haspopup="dialog"
              aria-expanded={{if this.isSearchSheetOpen "true" "false"}}
              {{on "click" this.toggleSearchSheet}}
            >
              <span class="fomio-sidebar__icon">{{icon "magnifying-glass"}}</span>
              <span class="fomio-sidebar__item-label">
                <span class="fomio-sidebar__search-title">{{this.searchLabel}}</span>
              </span>
            </button>
          {{else}}
            <button
              type="button"
              class="fomio-sidebar__search-launcher"
              aria-label={{this.searchLabel}}
              aria-haspopup="dialog"
              aria-expanded={{if this.isSearchSheetOpen "true" "false"}}
              {{on "click" this.toggleSearchSheet}}
            >
              <span class="fomio-sidebar__search-launcher-icon" aria-hidden="true">
                {{icon "magnifying-glass"}}
              </span>
              <span class="fomio-sidebar__search-launcher-body">
                <span class="fomio-sidebar__search-launcher-title">{{this.searchLabel}}</span>
              </span>
              <span class="fomio-sidebar__search-launcher-shortcut">
                {{this.searchShortcutLabel}}
              </span>
            </button>
          {{/if}}
        </div>

        {{! ── Zone B — Core navigation ───────────────────── }}
        <div class="fomio-sidebar__zone fomio-sidebar__zone--core">
          <a
            href="/latest"
              class="fomio-sidebar__item {{if (eq this.activeMasterContext 'home') 'is-active'}}"
            aria-current={{if this.isLatestActive "page"}}
            title={{this.latestLabel}}
          >
            <span class="fomio-sidebar__icon">{{icon "clock"}}</span>
            <span class="fomio-sidebar__item-label">{{this.latestLabel}}</span>
          </a>

          <a
            href="/hot"
            class="fomio-sidebar__item {{if this.isHotActive 'is-active'}}"
            aria-current={{if this.isHotActive "page"}}
            title={{this.hotLabel}}
          >
            <span class="fomio-sidebar__icon">{{icon "fire"}}</span>
            <span class="fomio-sidebar__item-label">{{this.hotLabel}}</span>
          </a>

          {{! ── Hub tree ── }}
          <div class="fomio-sidebar__section">
            <a
              href="/categories"
              class="fomio-sidebar__item {{if (eq this.activeMasterContext 'hubs') 'is-active'}}"
              aria-current={{if this.isHubsActive "page"}}
              title={{this.hubsLabel}}
              {{on "click" this.onHubsActivate}}
            >
              <span class="fomio-sidebar__icon">{{icon "compass"}}</span>
              <span class="fomio-sidebar__item-label">{{this.hubsLabel}}</span>
            </a>

            {{#if this.showHubsSecondaryList}}
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
            {{/if}}
          </div>

          {{#if this.currentUser}}
            <a
              href={{this.bookmarksUrl}}
              class="fomio-sidebar__item {{if (eq this.activeMasterContext 'bookmarks') 'is-active'}}"
              aria-current={{if this.isBookmarksActive "page"}}
              title={{this.bookmarksLabel}}
              {{on "click" this.onBookmarksActivate}}
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
            <button
              type="button"
              class="fomio-sidebar__item {{if (eq this.activeMasterContext 'notifications') 'is-active'}}"
              aria-current={{if this.isNotificationsActive "page"}}
              title={{this.notificationsLabel}}
              {{on "click" this.onNotificationsActivate}}
            >
              <span class="fomio-sidebar__icon">{{icon "bell"}}</span>
              {{#if this.notificationsBadge}}
                <span class="fomio-sidebar__badge">{{this.notificationsBadge}}</span>
              {{/if}}
              <span class="fomio-sidebar__item-label">{{this.notificationsLabel}}</span>
            </button>

            <a
              href={{this.profileUrl}}
              class="fomio-sidebar__item fomio-sidebar__item--profile {{if (eq this.activeMasterContext 'profile') 'is-active'}}"
              {{on "click" this.onProfileActivate}}
            >
              <span class="fomio-sidebar__icon">{{icon "user"}}</span>
              <span class="fomio-sidebar__item-label">{{this.currentUser.username}}</span>
            </a>
          {{else}}
            <a
              href={{this.profileUrl}}
              class="fomio-sidebar__item {{if (eq this.activeMasterContext 'profile') 'is-active'}}"
              {{on "click" this.onProfileActivate}}
            >
              <span class="fomio-sidebar__icon">{{icon "user"}}</span>
              <span class="fomio-sidebar__item-label">{{this.signInLabel}}</span>
            </a>
          {{/if}}
        </div>

      </nav>
    {{/if}}
  </template>
}
