import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioUserProfileSummary from "../../components/shared/fomio-user-profile-summary";
import FomioList from "../../components/shared/fomio-list";
import FomioListItem from "../../components/shared/fomio-list-item";
import { buildFomioHubCatalog } from "../../lib/fomio-hub-catalog";
import {
  getFomioNotificationsChildSections,
  getFomioProfileMasterSections,
  isOwnedActivitySectionPath,
} from "../../lib/fomio-account-sections";
import {
  isFomioShellPath,
  isOwnBookmarksPath,
  isOwnNotificationsPath,
  isUserProfilePath,
} from "../../lib/fomio-mobile-nav-paths";
import {
  clearPendingMasterPaneOverlay,
  PENDING_MASTER_PANE_OVERLAY_KEY,
} from "../../lib/fomio-master-pane-overlay-state";
const MASTER_PANE_CONTEXTS = ["hubs", "profile", "bookmarks", "notifications"];

export default class FomioMasterPane extends Component {
  @service router;
  @service site;
  @service currentUser;
  @service siteSettings;

  @tracked overlayOpen = false;
  @tracked overlayContext = null;
  @tracked hubExpansionState = {};
  @tracked fallbackProfileExpanded = false;

  clearPendingOverlay() {
    clearPendingMasterPaneOverlay();
  }

  constructor(...args) {
    super(...args);
    this._onOpenRequest = (event) => this.handleOpenRequest(event);
    this._onToggleRequest = (event) => this.handleToggleRequest(event);
    this._onKeydown = (event) => this.handleEscape(event);
    this._onResize = () => {
      this.syncOverlayEligibility();
      this.syncMasterDetailShellClasses();
    };
    this._onRouteDidChange = () => {
      this.closeOverlay("route-change");
      this.syncMasterDetailShellClasses();
      this.restorePendingOverlay();
    };
    if (typeof document !== "undefined") {
      window.addEventListener("fomio:master-pane:open", this._onOpenRequest);
      window.addEventListener("fomio:master-pane:toggle", this._onToggleRequest);
      document.addEventListener("keydown", this._onKeydown);
      window.addEventListener("resize", this._onResize);
      window.addEventListener("orientationchange", this._onResize);
    }
    if (typeof this.router?.on === "function") {
      this.router.on("routeDidChange", this._onRouteDidChange);
    }
    this.syncMasterDetailShellClasses();
    this.restorePendingOverlay();
  }

  willDestroy() {
    if (typeof document !== "undefined") {
      if (this._onOpenRequest) {
        window.removeEventListener("fomio:master-pane:open", this._onOpenRequest);
      }
      if (this._onToggleRequest) {
        window.removeEventListener("fomio:master-pane:toggle", this._onToggleRequest);
      }
      if (this._onResize) {
        window.removeEventListener("resize", this._onResize);
        window.removeEventListener("orientationchange", this._onResize);
      }
      document.body.classList.remove("fomio-master-pane-rail-open");
      document.body.classList.remove("fomio-settings-master-active");
      document.body.classList.remove("fomio-bookmarks-master-active");
      document.body.classList.remove("fomio-notifications-master-active");
      document.body.classList.remove("fomio-activity-master-active");
      document.body.classList.remove("fomio-profile-master-active");
    }
    if (typeof document !== "undefined" && this._onKeydown) {
      document.removeEventListener("keydown", this._onKeydown);
    }
    if (typeof this.router?.off === "function" && this._onRouteDidChange) {
      this.router.off("routeDidChange", this._onRouteDidChange);
    }
    super.willDestroy(...arguments);
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get activeMasterContext() {
    const p = this.currentPath;
    if (p === "/categories" || p.startsWith("/c/")) {
      return "hubs";
    }
    if (isOwnBookmarksPath(p, this.currentUser)) {
      return "bookmarks";
    }
    if (isOwnNotificationsPath(p, this.currentUser)) {
      return "notifications";
    }
    if (isUserProfilePath(p)) {
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

  get isOverlaySurface() {
    return this.isRailSurface || this.isExpandedOrCompactSurface;
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

  get shouldRenderMasterPane() {
    return (
      this.overlayOpen &&
      this.isOverlaySurface &&
      this.isShellActive &&
      isFomioShellPath(this.currentPath) &&
      MASTER_PANE_CONTEXTS.includes(this.overlayContext)
    );
  }

  get shouldRenderBackdrop() {
    return this.shouldRenderMasterPane && this.displayedMasterContext !== "profile";
  }

  get displayedMasterContext() {
    if (this.shouldRenderMasterPane) {
      return this.overlayContext;
    }

    return this.activeMasterContext;
  }

  get paneClass() {
    return this.isRailSurface ? "fomio-master-pane is-rail-overlay" : "fomio-master-pane";
  }

  get viewedUser() {
    return getOwner(this)?.lookup("controller:user")?.model ?? null;
  }

  get userController() {
    return getOwner(this)?.lookup("controller:user") ?? null;
  }

  get resolvedProfileUser() {
    if (this.viewedUser) {
      return this.viewedUser;
    }

    if (
      this.displayedMasterContext === "profile" &&
      this.currentUser?.username
    ) {
      return this.currentUser;
    }

    return null;
  }

  // Keep category source resilient across connector contexts.
  // Primary source mirrors sidebar/categories connectors: site.categories.
  // Fallbacks are safe reads only; no network fetches.
  get categoryPool() {
    const catalog = this.hubCatalog;

    if (
      typeof window !== "undefined" &&
      window.localStorage?.getItem("fomio_debug_master_pane") === "1"
    ) {
      // Debug is opt-in and removable; disabled by default.
      console.debug("[fomio-master-pane] categoryPool", {
        dedupedCount: catalog.categories.length,
        sample: catalog.categories.slice(0, 3).map((c) => ({
          id: c?.id,
          slug: c?.slug,
          parent_category_id: c?.parent_category_id,
          subcategory_ids: c?.subcategory_ids,
          name: c?.name,
        })),
      });
    }

    return catalog.categories;
  }

  get topLevelHubs() {
    return this.hubCatalog.topLevelHubs;
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
    if (!hub?.id) {
      return [];
    }
    return this.categoryPool.filter(
      (category) => category.parent_category_id === hub.id
    );
  }

  @action
  isHubExpanded(hub) {
    if (!hub?.id) {
      return false;
    }

    const explicitState = this.hubExpansionState[hub.id];
    if (typeof explicitState === "boolean") {
      return explicitState;
    }

    return hub.id === this.activeHubId;
  }

  @action
  toggleHub(hubId, event) {
    event?.preventDefault();
    event?.stopPropagation();

    const nextIsExpanded = !this.isHubExpanded({ id: hubId });
    this.hubExpansionState = {
      ...this.hubExpansionState,
      [hubId]: nextIsExpanded,
    };
  }

  @action
  closeOverlay(reason = "manual") {
    if (
      typeof window !== "undefined" &&
      window.localStorage?.getItem("fomio_debug_master_pane") === "1"
    ) {
      console.debug("[fomio-master-pane] close overlay", {
        reason,
        path: this.currentPath,
      });
    }
    this.overlayOpen = false;
    this.overlayContext = null;
    this.clearPendingOverlay();
    if (typeof document !== "undefined") {
      document.body.classList.remove("fomio-master-pane-rail-open");
    }
    this.syncMasterDetailShellClasses();
  }

  @action
  handleOpenRequest(event) {
    const context = event?.detail?.context;
    if (!MASTER_PANE_CONTEXTS.includes(context)) {
      return;
    }
    this.overlayContext = context;
    if (!this.isShellActive || !isFomioShellPath(this.currentPath)) {
      return;
    }
    this.overlayOpen = true;
    this.clearPendingOverlay();
    if (typeof document !== "undefined") {
      document.body.classList.add("fomio-master-pane-rail-open");
    }
    this.syncMasterDetailShellClasses();
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
  handleToggleRequest(event) {
    const context = event?.detail?.context;
    if (!MASTER_PANE_CONTEXTS.includes(context)) {
      return;
    }

    if (!this.isShellActive || !isFomioShellPath(this.currentPath)) {
      return;
    }
    this.clearPendingOverlay();

    const isSameContextOpen =
      this.overlayOpen && this.overlayContext === context;

    if (isSameContextOpen) {
      this.closeOverlay("toggle");
      return;
    }

    this.overlayOpen = true;
    this.overlayContext = context;
    if (typeof document !== "undefined") {
      document.body.classList.add("fomio-master-pane-rail-open");
    }
    this.syncMasterDetailShellClasses();
  }

  restorePendingOverlay() {
    if (
      typeof window === "undefined" ||
      !window.sessionStorage ||
      !this.isShellActive ||
      !isFomioShellPath(this.currentPath)
    ) {
      this.overlayContext = null;
      return;
    }

    this.overlayContext = null;

    const pendingContext = window.sessionStorage.getItem(
      PENDING_MASTER_PANE_OVERLAY_KEY
    );
    if (!MASTER_PANE_CONTEXTS.includes(pendingContext)) {
      return;
    }

    if (pendingContext !== this.activeMasterContext) {
      return;
    }

    window.sessionStorage.removeItem(PENDING_MASTER_PANE_OVERLAY_KEY);
    this.overlayOpen = true;
    this.overlayContext = pendingContext;
    if (typeof document !== "undefined") {
      document.body.classList.add("fomio-master-pane-rail-open");
    }
  }

  @action
  syncOverlayEligibility() {
    if (!this.overlayOpen) {
      return;
    }
    if (!this.isOverlaySurface) {
      this.closeOverlay("surface-change");
    }
  }

  syncMasterDetailShellClasses() {
    if (typeof document === "undefined") {
      return;
    }
    const overlayContext = this.shouldRenderMasterPane ? this.overlayContext : null;
    const overlayOpen = this.shouldRenderMasterPane;
    const isSettingsDesktopMasterPane =
      overlayContext === "profile" && this.isExpandedOrCompactSurface;
    const isBookmarksDesktopMasterPane =
      overlayContext === "bookmarks" && this.isExpandedOrCompactSurface;
    const isNotificationsDesktopMasterPane =
      overlayContext === "notifications" && this.isExpandedOrCompactSurface;
    const isActivityDesktopMasterPane =
      overlayContext === "profile" &&
      this.isExpandedOrCompactSurface &&
      isOwnedActivitySectionPath(this.currentPath);
    const isProfileDesktopMasterPane =
      overlayContext === "profile" && this.isExpandedOrCompactSurface;

    document.body.classList.toggle(
      "fomio-master-pane-rail-open",
      overlayOpen
    );

    document.body.classList.toggle(
      "fomio-settings-master-active",
      isSettingsDesktopMasterPane
    );
    document.body.classList.toggle(
      "fomio-bookmarks-master-active",
      isBookmarksDesktopMasterPane
    );
    document.body.classList.toggle(
      "fomio-notifications-master-active",
      isNotificationsDesktopMasterPane
    );
    document.body.classList.toggle(
      "fomio-activity-master-active",
      isActivityDesktopMasterPane
    );
    document.body.classList.toggle(
      "fomio-profile-master-active",
      isProfileDesktopMasterPane
    );
  }

  @action
  handleEscape(event) {
    if (!this.shouldRenderMasterPane) {
      return;
    }
    if (event.key === "Escape") {
      event.preventDefault();
      this.closeOverlay("escape");
    }
  }

  @action
  handleNavClick(event) {
    if (!this.shouldRenderMasterPane) {
      return;
    }
    if (event.target.closest("a[href]")) {
      this.closeOverlay("link-click");
    }
  }

  get titleLabel() {
    if (this.displayedMasterContext === "profile") {
      return (
        this.resolvedProfileUser?.name ||
        this.resolvedProfileUser?.username ||
        i18n(themePrefix("settings_master_pane.title"))
      );
    }
    if (this.displayedMasterContext === "bookmarks") {
      return i18n(themePrefix("bookmarks_master_pane.title"));
    }
    if (this.displayedMasterContext === "notifications") {
      return i18n(themePrefix("notifications_master_pane.title"));
    }
    return i18n(themePrefix("hubs_index.title"));
  }

  get descriptionLabel() {
    if (this.displayedMasterContext === "profile") {
      return null;
    }
    if (this.displayedMasterContext === "bookmarks") {
      return i18n(themePrefix("bookmarks_master_pane.description"));
    }
    if (this.displayedMasterContext === "notifications") {
      return i18n(themePrefix("notifications_master_pane.description"));
    }
    return i18n(themePrefix("hubs_index.description"));
  }

  get canExpandProfile() {
    if (this.userController?.canExpandProfile !== undefined) {
      return Boolean(this.userController.canExpandProfile);
    }

    return Boolean(
      this.displayedMasterContext === "profile" &&
        this.currentUser?.username &&
        this.resolvedProfileUser?.username &&
        String(this.currentUser.username).toLowerCase() ===
          String(this.resolvedProfileUser.username).toLowerCase() &&
        !this.resolvedProfileUser?.profile_hidden
    );
  }

  get collapsedInfoState() {
    if (this.userController?.collapsedInfoState) {
      return this.userController.collapsedInfoState;
    }

    if (!this.canExpandProfile) {
      return null;
    }

    return {
      isExpanded: this.fallbackProfileExpanded,
      icon: this.fallbackProfileExpanded ? "angles-up" : "angles-down",
      label: this.fallbackProfileExpanded ? "collapse_profile" : "expand_profile",
      ariaLabel: this.fallbackProfileExpanded
        ? "user.sr_collapse_profile"
        : "user.sr_expand_profile",
    };
  }

  get showExpandedDetails() {
    return Boolean(this.collapsedInfoState?.isExpanded);
  }

  get expandButtonLabel() {
    const labelKey = this.collapsedInfoState?.label;
    return labelKey ? i18n(`user.${labelKey}`) : null;
  }

  get expandButtonAriaLabel() {
    const labelKey = this.collapsedInfoState?.ariaLabel;
    return labelKey ? i18n(labelKey) : null;
  }

  get expandButtonIcon() {
    return this.collapsedInfoState?.icon ?? "angles-down";
  }

  get profileAdminSection() {
    return this.profileSections.find((section) => section.key === "manage-user") ?? null;
  }

  get profileNavSections() {
    return this.profileSections.filter((section) => section.key !== "manage-user");
  }

  get profileAdminHref() {
    return this.profileAdminSection?.href ?? null;
  }

  get profileAdminLabel() {
    return this.profileAdminSection ? i18n("admin.user.show_admin_profile") : null;
  }

  get profileMarkerText() {
    if (this.resolvedProfileUser?.admin) {
      return "Fomio Admin";
    }

    if (this.resolvedProfileUser?.moderator) {
      return "Moderator";
    }

    return null;
  }

  get profileExpandedInfoItems() {
    const user = this.resolvedProfileUser;
    const items = [];

    if (user?.created_at) {
      items.push({
        key: "created",
        label: i18n("user.created"),
        date: user.created_at,
      });
    }

    if (user?.last_posted_at) {
      items.push({
        key: "last-posted",
        label: i18n("user.last_posted"),
        date: user.last_posted_at,
      });
    }

    if (user?.last_seen_at) {
      items.push({
        key: "last-seen",
        label: i18n("user.last_seen"),
        date: user.last_seen_at,
      });
    }

    if (user?.profile_view_count) {
      items.push({
        key: "views",
        label: i18n("views"),
        value: String(user.profile_view_count),
      });
    }

    if (user?.trustLevel?.name) {
      items.push({
        key: "trust-level",
        label: i18n("user.trust_level"),
        value: user.trustLevel.name,
      });
    }

    return items;
  }

  @action
  toggleProfile() {
    if (this.userController?.toggleProfile) {
      this.userController.toggleProfile();
      return;
    }

    if (this.canExpandProfile) {
      this.fallbackProfileExpanded = !this.fallbackProfileExpanded;
    }
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

  get profileSections() {
    return getFomioProfileMasterSections({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
      siteSettings: this.siteSettings,
      viewedUser: this.resolvedProfileUser,
    }).map((section) => ({
      ...section,
      label: i18n(themePrefix(section.labelKey)),
    }));
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

  get notificationsLinks() {
    const login = "/login?fomio_web=1";
    const loggedOutKeys = [
      "all",
      "replies",
      "mentions",
      "likes",
      "messages",
      "settings",
    ];

    if (!this.currentUser?.username) {
      return loggedOutKeys.map((key) => ({
        key,
        label: i18n(themePrefix(`notifications_master_pane.${key}`)),
        href: login,
        isActive: false,
      }));
    }

    return getFomioNotificationsChildSections({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
    }).map((section) => ({
      key: section.key,
      label: i18n(themePrefix(section.labelKey)),
      href: section.href,
      isActive: section.isActive,
    }));
  }

  <template>
    {{#if this.shouldRenderMasterPane}}
      {{#if this.shouldRenderBackdrop}}
        <div
          class="fomio-master-pane-backdrop"
          aria-hidden="true"
          {{on "click" (fn this.closeOverlay "backdrop")}}
        ></div>
      {{/if}}

      {{! Touch intentionally has no Master Pane. The touch surface stays
          bottom-bar + detail only to preserve the mobile reading flow. }}
      <aside
        class={{this.paneClass}}
        aria-label={{this.titleLabel}}
      >
        <div class="fomio-master-pane__inner">
          {{#if (eq this.displayedMasterContext "profile")}}
            {{#if this.resolvedProfileUser}}
              <div class="fomio-master-pane__profile-summary">
                <FomioUserProfileSummary
                  @user={{this.resolvedProfileUser}}
                  @markerText={{this.profileMarkerText}}
                  @adminFirst={{true}}
                  @showExpand={{this.canExpandProfile}}
                  @expandButtonStyle="hub-toggle"
                  @expandButtonLabel={{this.expandButtonLabel}}
                  @expandButtonAriaLabel={{this.expandButtonAriaLabel}}
                  @expandButtonIcon={{this.expandButtonIcon}}
                  @showDetails={{this.showExpandedDetails}}
                  @onToggleExpand={{this.toggleProfile}}
                  @adminHref={{this.profileAdminHref}}
                  @adminLabel={{this.profileAdminLabel}}
                  @detailsItems={{this.profileExpandedInfoItems}}
                />
              </div>
            {{/if}}
          {{else}}
            <header class="fomio-master-pane__header">
              <h2 class="fomio-master-pane__title">{{this.titleLabel}}</h2>
              <p class="fomio-master-pane__description">{{this.descriptionLabel}}</p>
            </header>
          {{/if}}

          <nav
            class="fomio-master-pane__nav fomio-utility-list fomio-utility-list--bare"
            aria-label={{this.titleLabel}}
            {{on "click" this.handleNavClick}}
          >
            {{#if (eq this.displayedMasterContext "profile")}}
              <FomioList class="fomio-master-pane__nav-profile">
                {{#each this.profileNavSections as |link|}}
                  <FomioListItem
                    @href={{link.href}}
                    @title={{link.label}}
                    @isActive={{link.isActive}}
                  />
                {{/each}}
              </FomioList>
            {{else if (eq this.displayedMasterContext "bookmarks")}}
              <FomioList class="fomio-master-pane__nav-bookmarks">
                {{#each this.bookmarksLinks as |link|}}
                  <FomioListItem
                    @href={{link.href}}
                    @title={{link.label}}
                    @isActive={{link.isActive}}
                  />
                {{/each}}
              </FomioList>
            {{else if (eq this.displayedMasterContext "notifications")}}
              <FomioList class="fomio-master-pane__nav-notifications">
                {{#each this.notificationsLinks as |link|}}
                  <FomioListItem
                    @href={{link.href}}
                    @title={{link.label}}
                    @isActive={{link.isActive}}
                  />
                {{/each}}
              </FomioList>
            {{else}}
              {{#each this.topLevelHubs as |hub|}}
                {{#let (this.childTeretsForHub hub) as |terets|}}
                  <div class="fomio-master-pane__group">
                    <div class="fomio-master-pane__hub-row {{if (this.isHubActive hub) 'is-active'}}">
                      <a
                        href="/c/{{hub.slug}}/{{hub.id}}"
                        class="fomio-master-pane__item fomio-utility-row {{if (this.isHubActive hub) 'is-active'}}"
                        aria-current={{if (this.isHubActive hub) "page"}}
                        title={{hub.name}}
                      >
                        <span
                          class="fomio-master-pane__dot"
                          style="background: #{{hub.color}}"
                          aria-hidden="true"
                        ></span>
                        <span class="fomio-master-pane__name fomio-utility-row__label">{{hub.name}}</span>
                      </a>

                      {{#if terets.length}}
                        <button
                          type="button"
                          class="fomio-master-pane__hub-toggle {{if (this.isHubExpanded hub) 'is-open'}}"
                          aria-expanded={{if (this.isHubExpanded hub) "true" "false"}}
                          aria-label="{{hub.name}} terets"
                          {{on "click" (fn this.toggleHub hub.id)}}
                        >
                          {{icon "angle-right"}}
                        </button>
                      {{/if}}
                    </div>

                    {{#if (this.isHubExpanded hub)}}
                      {{#if terets.length}}
                        <ul class="fomio-master-pane__teret-list">
                          {{#each terets as |teret|}}
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
                {{/let}}
              {{/each}}
              {{#if this.hasMoreHubs}}
                <a href="/categories" class="fomio-master-pane__item">
                  <span class="fomio-master-pane__name fomio-utility-row__label">{{i18n (themePrefix "sidebar.all_hubs")}}</span>
                </a>
              {{/if}}
            {{/if}}
          </nav>
        </div>
      </aside>
    {{/if}}
  </template>
}
