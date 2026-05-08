import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// Keep in sync with other shell connectors. Theme files cannot share modules.
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

export default class FomioMasterPane extends Component {
  @service router;
  @service site;
  @service currentUser;

  @tracked railOverlayOpen = false;
  @tracked railOverlayContext = null;

  constructor(...args) {
    super(...args);
    this._onOpenRequest = (event) => this.handleOpenRequest(event);
    this._onKeydown = (event) => this.handleEscape(event);
    this._onResize = () => {
      this.syncRailOverlayEligibility();
      this.syncSettingsDetailShellClass();
    };
    this._onRouteDidChange = () => {
      this.closeRailOverlay("route-change");
      this.syncSettingsDetailShellClass();
    };
    if (typeof document !== "undefined") {
      window.addEventListener("fomio:master-pane:open", this._onOpenRequest);
      document.addEventListener("keydown", this._onKeydown);
      window.addEventListener("resize", this._onResize);
      window.addEventListener("orientationchange", this._onResize);
    }
    if (typeof this.router?.on === "function") {
      this.router.on("routeDidChange", this._onRouteDidChange);
    }
    this.syncSettingsDetailShellClass();
  }

  willDestroy() {
    if (typeof document !== "undefined") {
      if (this._onOpenRequest) {
        window.removeEventListener("fomio:master-pane:open", this._onOpenRequest);
      }
      if (this._onResize) {
        window.removeEventListener("resize", this._onResize);
        window.removeEventListener("orientationchange", this._onResize);
      }
      document.body.classList.remove("fomio-master-pane-rail-open");
      document.body.classList.remove("fomio-settings-master-active");
    }
    if (typeof document !== "undefined" && this._onKeydown) {
      document.removeEventListener("keydown", this._onKeydown);
    }
    if (typeof this.router?.off === "function" && this._onRouteDidChange) {
      this.router.off("routeDidChange", this._onRouteDidChange);
    }
    super.willDestroy(...arguments);
  }

  normalizeCategorySource(source) {
    if (!source) {
      return [];
    }

    if (Array.isArray(source)) {
      return source;
    }

    if (typeof source.toArray === "function") {
      const normalized = source.toArray();
      return Array.isArray(normalized) ? normalized : [];
    }

    if (Array.isArray(source.content)) {
      return source.content;
    }

    if (typeof source.length === "number") {
      try {
        return Array.from(source);
      } catch {
        return [];
      }
    }

    return [];
  }

  dedupeCategories(categories) {
    const seen = new Set();

    return categories.filter((category) => {
      const key = category?.id ?? category?.slug;
      if (!key || seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get activeMasterContext() {
    const p = this.currentPath;
    if (p === "/categories" || p.startsWith("/c/")) {
      return "hubs";
    }
    if (p.includes("bookmarks")) {
      return "bookmarks";
    }
    if (p.startsWith("/notifications")) {
      return "notifications";
    }
    if (p.startsWith("/u/") || p.startsWith("/my/")) {
      return "profile";
    }
    return "home";
  }

  get isExpandedOrCompactSurface() {
    if (typeof document === "undefined") {
      return false;
    }
    const classes = document.body?.classList;
    return (
      classes?.contains("fomio-surface-expanded") ||
      classes?.contains("fomio-surface-compact-desktop")
    );
  }

  get isRailSurface() {
    if (typeof document === "undefined") {
      return false;
    }
    return document.body?.classList?.contains("fomio-surface-rail");
  }

  get isShellActive() {
    if (typeof document === "undefined") {
      return false;
    }
    const classes = document.body?.classList;
    return (
      classes?.contains("fomio-sidebar-active") &&
      !classes?.contains("fomio-auth-mode")
    );
  }

  get shouldRenderDesktopMasterPane() {
    // Persistent master pane: active only on expanded/compact desktop surfaces.
    // This is the long-lived "Master" layer in [Sidebar OS][Master Pane][Detail].
    return (
      (this.activeMasterContext === "hubs" ||
        this.activeMasterContext === "profile" ||
        this.activeMasterContext === "bookmarks") &&
      this.isExpandedOrCompactSurface
    );
  }

  get shouldRenderRailMasterPaneOverlay() {
    // Rail overlay: temporary contextual depth above rail/content.
    // It reuses the same Hub/Teret list structure as the desktop master pane.
    return (
      this.railOverlayOpen &&
      this.railOverlayContext === "hubs" &&
      this.isRailSurface &&
      this.isShellActive &&
      !isAuthPath(this.currentPath)
    );
  }

  get shouldRenderMasterPane() {
    if (isAuthPath(this.currentPath)) {
      return false;
    }
    if (!this.isShellActive) {
      return false;
    }
    return this.shouldRenderDesktopMasterPane || this.shouldRenderRailMasterPaneOverlay;
  }

  get shouldRenderRailBackdrop() {
    return this.shouldRenderRailMasterPaneOverlay;
  }

  get paneClass() {
    return this.shouldRenderRailMasterPaneOverlay ? "fomio-master-pane is-rail-overlay" : "fomio-master-pane";
  }

  // Keep category source resilient across connector contexts.
  // Primary source mirrors sidebar/categories connectors: site.categories.
  // Fallbacks are safe reads only; no network fetches.
  get categoryPool() {
    const candidates = [
      this.site?.categories,
      this.site?.categoryList?.categories,
      this.site?.categoriesList,
      this.site?.site?.categories,
      this.args?.outletArgs?.site?.categories,
      this.args?.outletArgs?.categoryList?.categories,
    ];

    const sourceMeta = candidates.map((source) => ({
      exists: Boolean(source),
      isArray: Array.isArray(source),
      hasToArray: typeof source?.toArray === "function",
      length: typeof source?.length === "number" ? source.length : null,
      contentLength: Array.isArray(source?.content) ? source.content.length : null,
      keys: source ? Object.keys(source).slice(0, 12) : [],
    }));

    const rawCategories = candidates
      .flatMap((source) => this.normalizeCategorySource(source))
      .filter((category) => Boolean(category && typeof category === "object"));
    const categories = this.dedupeCategories(rawCategories);

    if (
      typeof window !== "undefined" &&
      window.localStorage?.getItem("fomio_debug_master_pane") === "1"
    ) {
      // Debug is opt-in and removable; disabled by default.
      console.debug("[fomio-master-pane] categoryPool", {
        rawCount: rawCategories.length,
        dedupedCount: categories.length,
        sourceMeta,
        sample: categories.slice(0, 3).map((c) => ({
          id: c?.id,
          slug: c?.slug,
          parent_category_id: c?.parent_category_id,
          subcategory_ids: c?.subcategory_ids,
          name: c?.name,
        })),
      });
    }

    return categories;
  }

  get topLevelHubs() {
    return this.categoryPool
      .filter(
        (category) =>
          category &&
          (category.parent_category_id === null ||
            category.parent_category_id === undefined) &&
          category.slug !== "uncategorized"
      )
      .slice(0, 16);
  }

  // /categories keeps overview state with no selected row.
  // /c/:slug/:id selects that hub.
  // /c/:hubSlug/:teretSlug/:teretId maps back to its parent hub.
  get activeHubId() {
    const p = this.currentPath;
    if (!p.startsWith("/c/")) {
      return null;
    }

    const parts = p.split("/").filter(Boolean);
    if (parts[2] && /^\d+$/.test(parts[2])) {
      return parseInt(parts[2], 10);
    }

    if (parts[3] && /^\d+$/.test(parts[3])) {
      const teretId = parseInt(parts[3], 10);
      const teret = this.categoryPool.find((category) => category.id === teretId);
      return teret?.parent_category_id ?? null;
    }

    return null;
  }

  // /c/:hubSlug/:teretSlug/:teretId selects this teret. /categories and /c/:slug/:id return null.
  get activeTeretId() {
    const p = this.currentPath;
    if (!p.startsWith("/c/")) {
      return null;
    }
    const parts = p.split("/").filter(Boolean);
    if (parts[3] && /^\d+$/.test(parts[3])) {
      return parseInt(parts[3], 10);
    }
    return null;
  }

  get childTeretsForActiveHub() {
    if (!this.activeHubId) {
      return [];
    }
    return this.categoryPool.filter(
      (category) => category.parent_category_id === this.activeHubId
    );
  }

  @action
  isHubActive(hub) {
    return hub?.id === this.activeHubId;
  }

  @action
  isTeretActive(teret) {
    return teret?.id === this.activeTeretId;
  }

  @action
  childTeretsForHub(hub) {
    if (!hub?.id || hub.id !== this.activeHubId) {
      return [];
    }
    return this.childTeretsForActiveHub;
  }

  @action
  closeRailOverlay(reason = "manual") {
    if (
      typeof window !== "undefined" &&
      window.localStorage?.getItem("fomio_debug_master_pane") === "1"
    ) {
      console.debug("[fomio-master-pane] close overlay", {
        reason,
        path: this.currentPath,
      });
    }
    this.railOverlayOpen = false;
    this.railOverlayContext = null;
    if (typeof document !== "undefined") {
      document.body.classList.remove("fomio-master-pane-rail-open");
    }
    this.syncSettingsDetailShellClass();
  }

  @action
  handleOpenRequest(event) {
    const context = event?.detail?.context;
    if (context !== "hubs") {
      return;
    }
    if (!this.isRailSurface || !this.isShellActive || isAuthPath(this.currentPath)) {
      return;
    }
    this.railOverlayOpen = true;
    this.railOverlayContext = "hubs";
    if (typeof document !== "undefined") {
      document.body.classList.add("fomio-master-pane-rail-open");
    }
    this.syncSettingsDetailShellClass();
    if (
      typeof window !== "undefined" &&
      window.localStorage?.getItem("fomio_debug_master_pane") === "1"
    ) {
      console.debug("[fomio-master-pane] received open event", {
        context,
        path: this.currentPath,
      });
    }
  }

  @action
  syncRailOverlayEligibility() {
    if (!this.railOverlayOpen) {
      return;
    }
    if (!this.isRailSurface) {
      this.closeRailOverlay("surface-change");
    }
  }

  syncSettingsDetailShellClass() {
    if (typeof document === "undefined") {
      return;
    }
    const isSettingsDesktopMasterPane =
      this.activeMasterContext === "profile" &&
      this.isExpandedOrCompactSurface &&
      this.isShellActive &&
      !isAuthPath(this.currentPath);
    document.body.classList.toggle(
      "fomio-settings-master-active",
      isSettingsDesktopMasterPane
    );
  }

  @action
  handleEscape(event) {
    if (!this.shouldRenderRailMasterPaneOverlay) {
      return;
    }
    if (event.key === "Escape") {
      event.preventDefault();
      this.closeRailOverlay("escape");
    }
  }

  @action
  handleNavClick(event) {
    if (!this.shouldRenderRailMasterPaneOverlay) {
      return;
    }
    if (event.target.closest("a[href]")) {
      this.closeRailOverlay("link-click");
    }
  }

  get titleLabel() {
    if (this.activeMasterContext === "profile") {
      return i18n(themePrefix("settings_master_pane.title"));
    }
    if (this.activeMasterContext === "bookmarks") {
      return i18n(themePrefix("bookmarks_master_pane.title"));
    }
    return i18n(themePrefix("hubs_index.title"));
  }

  get descriptionLabel() {
    if (this.activeMasterContext === "profile") {
      return i18n(themePrefix("settings_master_pane.description"));
    }
    if (this.activeMasterContext === "bookmarks") {
      return i18n(themePrefix("bookmarks_master_pane.description"));
    }
    return i18n(themePrefix("hubs_index.description"));
  }

  get profileBasePath() {
    const username = this.currentUser?.username;
    return username ? `/u/${username}` : "/login?fomio_web=1";
  }

  buildSettingsPath(path) {
    if (!this.currentUser?.username) {
      return "/login?fomio_web=1";
    }
    return `${this.profileBasePath}${path}`;
  }

  isCurrentPath(...patterns) {
    const path = this.currentPath.replace(/\/+$/, "") || "/";
    return patterns.some((pattern) => {
      if (!pattern) {
        return false;
      }
      if (pattern.endsWith("*")) {
        return path.startsWith(pattern.slice(0, -1));
      }
      return path === pattern || path.startsWith(`${pattern}/`);
    });
  }

  get settingsLinks() {
    const base = this.profileBasePath;
    return [
      {
        key: "summary",
        label: i18n(themePrefix("settings_master_pane.summary")),
        href: this.buildSettingsPath("/summary"),
        isActive: this.isCurrentPath(`${base}/summary`, "/my/summary"),
      },
      {
        key: "activity",
        label: i18n(themePrefix("settings_master_pane.activity")),
        href: this.buildSettingsPath("/activity"),
        isActive: this.isCurrentPath(`${base}/activity`, "/my/activity*"),
      },
      {
        key: "bookmarks",
        label: i18n(themePrefix("settings_master_pane.bookmarks")),
        href: this.buildSettingsPath("/activity/bookmarks"),
        isActive: this.isCurrentPath(`${base}/activity/bookmarks`, "/my/activity/bookmarks*"),
      },
      {
        key: "preferences",
        label: i18n(themePrefix("settings_master_pane.preferences")),
        href: this.buildSettingsPath("/preferences"),
        isActive: this.isCurrentPath(`${base}/preferences`, "/my/preferences*"),
      },
      {
        key: "account",
        label: i18n(themePrefix("settings_master_pane.account")),
        href: this.buildSettingsPath("/preferences/account"),
        isActive: this.isCurrentPath(`${base}/preferences/account`, "/my/preferences/account*"),
      },
      {
        key: "security",
        label: i18n(themePrefix("settings_master_pane.security")),
        href: this.buildSettingsPath("/preferences/security"),
        isActive: this.isCurrentPath(`${base}/preferences/security`, "/my/preferences/security*"),
      },
      {
        key: "emails",
        label: i18n(themePrefix("settings_master_pane.emails")),
        href: this.buildSettingsPath("/preferences/emails"),
        isActive: this.isCurrentPath(`${base}/preferences/emails`, "/my/preferences/emails*"),
      },
      {
        key: "notifications",
        label: i18n(themePrefix("settings_master_pane.notifications")),
        href: this.buildSettingsPath("/preferences/notifications"),
        isActive: this.isCurrentPath(
          `${base}/preferences/notifications`,
          "/my/preferences/notifications*"
        ),
      },
      {
        key: "interface",
        label: i18n(themePrefix("settings_master_pane.interface")),
        href: this.buildSettingsPath("/preferences/interface"),
        isActive: this.isCurrentPath(`${base}/preferences/interface`, "/my/preferences/interface*"),
      },
    ];
  }

  get bookmarksBasePath() {
    const username = this.currentUser?.username;
    return username ? `/u/${username}/activity` : "/login?fomio_web=1";
  }

  buildBookmarksPath(path = "") {
    if (!this.currentUser?.username) {
      return "/login?fomio_web=1";
    }
    return `${this.bookmarksBasePath}${path}`;
  }

  get bookmarksLinks() {
    const base = this.bookmarksBasePath;
    return [
      {
        key: "all",
        label: i18n(themePrefix("bookmarks_master_pane.all")),
        href: this.buildBookmarksPath("/bookmarks"),
        isActive: this.isCurrentPath(`${base}/bookmarks`, "/my/activity/bookmarks"),
      },
      {
        key: "saved_bytes",
        label: i18n(themePrefix("bookmarks_master_pane.saved_bytes")),
        href: this.buildBookmarksPath("/bookmarks"),
        isActive: this.isCurrentPath(`${base}/bookmarks`, "/my/activity/bookmarks"),
      },
      {
        key: "activity",
        label: i18n(themePrefix("bookmarks_master_pane.activity")),
        href: this.buildBookmarksPath(""),
        isActive: this.isCurrentPath(`${base}`, "/my/activity*"),
      },
    ];
  }

  <template>
    {{#if this.shouldRenderMasterPane}}
      {{#if this.shouldRenderRailBackdrop}}
        <div
          class="fomio-master-pane-backdrop"
          aria-hidden="true"
          {{on "click" (fn this.closeRailOverlay "backdrop")}}
        ></div>
      {{/if}}

      {{! Touch intentionally has no Master Pane. The touch surface stays
          bottom-bar + detail only to preserve the mobile reading flow. }}
      <aside
        class={{this.paneClass}}
        aria-label={{this.titleLabel}}
      >
        <div class="fomio-master-pane__inner">
          <header class="fomio-master-pane__header">
            <h2 class="fomio-master-pane__title">{{this.titleLabel}}</h2>
            <p class="fomio-master-pane__description">{{this.descriptionLabel}}</p>
          </header>

          <nav
            class="fomio-master-pane__nav"
            aria-label={{this.titleLabel}}
            {{on "click" this.handleNavClick}}
          >
            {{#if (eq this.activeMasterContext "profile")}}
              {{#each this.settingsLinks as |link|}}
                <a
                  href={{link.href}}
                  class="fomio-master-pane__item {{if link.isActive 'is-active'}}"
                  aria-current={{if link.isActive "page"}}
                >
                  <span class="fomio-master-pane__name">{{link.label}}</span>
                </a>
              {{/each}}
            {{else if (eq this.activeMasterContext "bookmarks")}}
              {{#each this.bookmarksLinks as |link|}}
                <a
                  href={{link.href}}
                  class="fomio-master-pane__item {{if link.isActive 'is-active'}}"
                  aria-current={{if link.isActive "page"}}
                >
                  <span class="fomio-master-pane__name">{{link.label}}</span>
                </a>
              {{/each}}
            {{else}}
              {{#each this.topLevelHubs as |hub|}}
                <div class="fomio-master-pane__group">
                  <a
                    href="/c/{{hub.slug}}/{{hub.id}}"
                    class="fomio-master-pane__item {{if (this.isHubActive hub) 'is-active'}}"
                    aria-current={{if (this.isHubActive hub) "page"}}
                    title={{hub.name}}
                  >
                    <span
                      class="fomio-master-pane__dot"
                      style="background: #{{hub.color}}"
                      aria-hidden="true"
                    ></span>
                    <span class="fomio-master-pane__name">{{hub.name}}</span>
                  </a>

                  {{#if (this.isHubActive hub)}}
                    {{#if this.childTeretsForActiveHub.length}}
                      <ul class="fomio-master-pane__teret-list">
                        {{#each (this.childTeretsForHub hub) as |teret|}}
                          <li>
                            <a
                              href="/c/{{hub.slug}}/{{teret.slug}}/{{teret.id}}"
                              class="fomio-master-pane__teret-item {{if (this.isTeretActive teret) 'is-active'}}"
                              aria-current={{if (this.isTeretActive teret) "page"}}
                            >
                              {{teret.name}}
                            </a>
                          </li>
                        {{/each}}
                      </ul>
                    {{/if}}
                  {{/if}}
                </div>
              {{/each}}
            {{/if}}
          </nav>
        </div>
      </aside>
    {{/if}}
  </template>
}
