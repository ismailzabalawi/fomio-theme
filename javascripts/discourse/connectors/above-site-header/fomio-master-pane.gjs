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
import { buildFomioHubCatalog } from "../../lib/fomio-hub-catalog";
import {
  getFomioProfileMasterSections,
  isOwnedActivitySectionPath,
} from "../../lib/fomio-account-sections";
import {
  isFomioShellPath,
  isOwnBookmarksPath,
  isOwnNotificationsPath,
  isUserProfilePath,
} from "../../lib/fomio-mobile-nav-paths";
const RAIL_OVERLAY_CONTEXTS = ["hubs", "profile", "bookmarks", "notifications"];
const PENDING_RAIL_OVERLAY_KEY = "fomio_pending_rail_overlay_context";

export default class FomioMasterPane extends Component {
  @service router;
  @service site;
  @service currentUser;
  @service siteSettings;

  @tracked railOverlayOpen = false;
  @tracked railOverlayContext = null;
  @tracked hubExpansionState = {};

  constructor(...args) {
    super(...args);
    this._onOpenRequest = (event) => this.handleOpenRequest(event);
    this._onToggleRequest = (event) => this.handleToggleRequest(event);
    this._onKeydown = (event) => this.handleEscape(event);
    this._onResize = () => {
      this.syncRailOverlayEligibility();
      this.syncMasterDetailShellClasses();
    };
    this._onRouteDidChange = () => {
      this.closeRailOverlay("route-change");
      this.syncMasterDetailShellClasses();
      this.restorePendingRailOverlay();
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
    this.restorePendingRailOverlay();
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
        this.activeMasterContext === "bookmarks" ||
        this.activeMasterContext === "notifications") &&
      this.isExpandedOrCompactSurface
    );
  }

  get shouldRenderRailMasterPaneOverlay() {
    // Rail overlay: temporary contextual depth above rail/content.
    // It reuses the same Hub/Teret list structure as the desktop master pane.
    return (
      (this.railOverlayOpen || this.shouldForceRailProfilePane) &&
      RAIL_OVERLAY_CONTEXTS.includes(this.railOverlayContext) &&
      this.isRailSurface &&
      this.isShellActive &&
      isFomioShellPath(this.currentPath)
    );
  }

  get shouldForceRailProfilePane() {
    return (
      this.activeMasterContext === "profile" &&
      this.isRailSurface &&
      this.isShellActive &&
      isFomioShellPath(this.currentPath)
    );
  }

  get shouldRenderMasterPane() {
    if (!isFomioShellPath(this.currentPath)) {
      return false;
    }
    if (!this.isShellActive) {
      return false;
    }
    return this.shouldRenderDesktopMasterPane || this.shouldRenderRailMasterPaneOverlay;
  }

  get shouldRenderRailBackdrop() {
    return this.shouldRenderRailMasterPaneOverlay && !this.shouldForceRailProfilePane;
  }

  get paneClass() {
    return this.shouldRenderRailMasterPaneOverlay ? "fomio-master-pane is-rail-overlay" : "fomio-master-pane";
  }

  get viewedUser() {
    return getOwner(this)?.lookup("controller:user")?.model ?? null;
  }

  get userController() {
    return getOwner(this)?.lookup("controller:user") ?? null;
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
    this.railOverlayContext = this.shouldForceRailProfilePane ? "profile" : null;
    if (typeof document !== "undefined") {
      document.body.classList.toggle(
        "fomio-master-pane-rail-open",
        this.shouldForceRailProfilePane
      );
    }
    this.syncMasterDetailShellClasses();
  }

  @action
  handleOpenRequest(event) {
    const context = event?.detail?.context;
    if (!RAIL_OVERLAY_CONTEXTS.includes(context)) {
      return;
    }
    this.railOverlayContext = context;
    if (
      !this.isRailSurface ||
      !this.isShellActive ||
      !isFomioShellPath(this.currentPath)
    ) {
      return;
    }
    this.railOverlayOpen = true;
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
    if (!RAIL_OVERLAY_CONTEXTS.includes(context)) {
      return;
    }
    this.railOverlayContext = context;
    if (
      !this.isRailSurface ||
      !this.isShellActive ||
      !isFomioShellPath(this.currentPath)
    ) {
      return;
    }
    if (typeof window !== "undefined" && window.sessionStorage) {
      window.sessionStorage.removeItem(PENDING_RAIL_OVERLAY_KEY);
    }

    if (this.railOverlayOpen && this.railOverlayContext === context) {
      if (context === "profile" && this.shouldForceRailProfilePane) {
        return;
      }
      this.closeRailOverlay("toggle");
      return;
    }

    this.railOverlayOpen = true;
    this.railOverlayContext = context;
    if (typeof document !== "undefined") {
      document.body.classList.add("fomio-master-pane-rail-open");
    }
    this.syncMasterDetailShellClasses();
  }

  restorePendingRailOverlay() {
    if (
      typeof window === "undefined" ||
      !window.sessionStorage ||
      !this.isRailSurface ||
      !this.isShellActive ||
      !isFomioShellPath(this.currentPath)
    ) {
      this.railOverlayContext = this.activeMasterContext;
      return;
    }

    this.railOverlayContext = this.activeMasterContext;

    const pendingContext = window.sessionStorage.getItem(PENDING_RAIL_OVERLAY_KEY);
    if (!RAIL_OVERLAY_CONTEXTS.includes(pendingContext)) {
      if (this.shouldForceRailProfilePane && typeof document !== "undefined") {
        document.body.classList.add("fomio-master-pane-rail-open");
      }
      return;
    }

    if (pendingContext !== this.activeMasterContext) {
      return;
    }

    window.sessionStorage.removeItem(PENDING_RAIL_OVERLAY_KEY);
    this.railOverlayOpen = true;
    this.railOverlayContext = pendingContext;
    if (typeof document !== "undefined") {
      document.body.classList.add("fomio-master-pane-rail-open");
    }
  }

  @action
  syncRailOverlayEligibility() {
    if (!this.railOverlayOpen) {
      if (this.shouldForceRailProfilePane && typeof document !== "undefined") {
        document.body.classList.add("fomio-master-pane-rail-open");
      }
      return;
    }
    if (!this.isRailSurface) {
      this.closeRailOverlay("surface-change");
    }
  }

  syncMasterDetailShellClasses() {
    if (typeof document === "undefined") {
      return;
    }
    const desktopShell =
      this.isExpandedOrCompactSurface &&
      this.isShellActive &&
      isFomioShellPath(this.currentPath);

    const isSettingsDesktopMasterPane =
      this.activeMasterContext === "profile" && desktopShell;

    const isBookmarksDesktopMasterPane =
      this.activeMasterContext === "bookmarks" && desktopShell;

    const isNotificationsDesktopMasterPane =
      this.activeMasterContext === "notifications" && desktopShell;

    const isActivityDesktopMasterPane =
      this.activeMasterContext === "profile" &&
      desktopShell &&
      isOwnedActivitySectionPath(this.currentPath);

    const isProfileDesktopMasterPane =
      this.activeMasterContext === "profile" &&
      ((desktopShell && this.isExpandedOrCompactSurface) ||
        (this.isRailSurface &&
          this.isShellActive &&
          isFomioShellPath(this.currentPath) &&
          this.shouldForceRailProfilePane));

    const shouldShowRailPane =
      this.isRailSurface &&
      this.isShellActive &&
      isFomioShellPath(this.currentPath) &&
      (this.railOverlayOpen || this.shouldForceRailProfilePane);

    document.body.classList.toggle(
      "fomio-master-pane-rail-open",
      shouldShowRailPane
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
      return (
        this.viewedUser?.name ||
        this.viewedUser?.username ||
        i18n(themePrefix("settings_master_pane.title"))
      );
    }
    if (this.activeMasterContext === "bookmarks") {
      return i18n(themePrefix("bookmarks_master_pane.title"));
    }
    if (this.activeMasterContext === "notifications") {
      return i18n(themePrefix("notifications_master_pane.title"));
    }
    return i18n(themePrefix("hubs_index.title"));
  }

  get descriptionLabel() {
    if (this.activeMasterContext === "profile") {
      return null;
    }
    if (this.activeMasterContext === "bookmarks") {
      return i18n(themePrefix("bookmarks_master_pane.description"));
    }
    if (this.activeMasterContext === "notifications") {
      return i18n(themePrefix("notifications_master_pane.description"));
    }
    return i18n(themePrefix("hubs_index.description"));
  }

  get canExpandProfile() {
    return Boolean(this.userController?.canExpandProfile);
  }

  get collapsedInfoState() {
    return this.userController?.collapsedInfoState ?? null;
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
    if (this.viewedUser?.admin) {
      return i18n("admin.title");
    }

    if (this.viewedUser?.moderator) {
      return i18n("moderator");
    }

    return null;
  }

  get profileExpandedInfoItems() {
    const user = this.viewedUser;
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
    this.userController?.toggleProfile?.();
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
      viewedUser: this.viewedUser,
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
    const username = this.currentUser?.username;
    if (!username) {
      return [
        {
          key: "all",
          label: i18n(themePrefix("notifications_master_pane.all")),
          href: login,
          isActive: false,
        },
        {
          key: "replies",
          label: i18n(themePrefix("notifications_master_pane.replies")),
          href: login,
          isActive: false,
        },
        {
          key: "mentions",
          label: i18n(themePrefix("notifications_master_pane.mentions")),
          href: login,
          isActive: false,
        },
        {
          key: "likes",
          label: i18n(themePrefix("notifications_master_pane.likes")),
          href: login,
          isActive: false,
        },
        {
          key: "messages",
          label: i18n(themePrefix("notifications_master_pane.messages")),
          href: login,
          isActive: false,
        },
        {
          key: "settings",
          label: i18n(themePrefix("notifications_master_pane.settings")),
          href: login,
          isActive: false,
        },
      ];
    }

    const u = `/u/${username}`;
    const p = this.currentPath.replace(/\/+$/, "") || "/";

    const allActive =
      p === "/notifications" ||
      p === `${u}/notifications` ||
      p === "/my/notifications";

    const repliesActive =
      p === `${u}/notifications/responses` ||
      p.startsWith(`${u}/notifications/responses/`) ||
      p === "/my/notifications/responses" ||
      p.startsWith("/my/notifications/responses/");

    const mentionsActive =
      p === `${u}/notifications/mentions` ||
      p.startsWith(`${u}/notifications/mentions/`) ||
      p === "/my/notifications/mentions" ||
      p.startsWith("/my/notifications/mentions/");

    const likesActive =
      p === `${u}/notifications/likes-received` ||
      p.startsWith(`${u}/notifications/likes-received/`) ||
      p === "/my/notifications/likes-received" ||
      p.startsWith("/my/notifications/likes-received/");

    const messagesActive =
      p === `${u}/messages` ||
      p.startsWith(`${u}/messages/`) ||
      p === "/my/messages" ||
      p.startsWith("/my/messages/");

    const settingsActive = this.isCurrentPath(
      `${u}/preferences/notifications`,
      "/my/preferences/notifications*"
    );

    return [
      {
        key: "all",
        label: i18n(themePrefix("notifications_master_pane.all")),
        href: "/notifications",
        isActive: allActive,
      },
      {
        key: "replies",
        label: i18n(themePrefix("notifications_master_pane.replies")),
        href: `${u}/notifications/responses`,
        isActive: repliesActive,
      },
      {
        key: "mentions",
        label: i18n(themePrefix("notifications_master_pane.mentions")),
        href: `${u}/notifications/mentions`,
        isActive: mentionsActive,
      },
      {
        key: "likes",
        label: i18n(themePrefix("notifications_master_pane.likes")),
        href: `${u}/notifications/likes-received`,
        isActive: likesActive,
      },
      {
        key: "messages",
        label: i18n(themePrefix("notifications_master_pane.messages")),
        href: `${u}/messages`,
        isActive: messagesActive,
      },
      {
        key: "settings",
        label: i18n(themePrefix("notifications_master_pane.settings")),
        href: `${u}/preferences/notifications`,
        isActive: settingsActive,
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
          {{#if (eq this.activeMasterContext "profile")}}
            {{#if this.viewedUser}}
              <div class="fomio-master-pane__profile-summary">
                <FomioUserProfileSummary
                  @user={{this.viewedUser}}
                  @markerText={{this.profileMarkerText}}
                  @adminFirst={{true}}
                  @showExpand={{this.canExpandProfile}}
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
            {{#if (eq this.activeMasterContext "profile")}}
              {{#each this.profileNavSections as |link|}}
                <a
                  href={{link.href}}
                  class="fomio-master-pane__item fomio-utility-row {{if link.isActive 'is-active'}}"
                  aria-current={{if link.isActive "page"}}
                >
                  <span class="fomio-master-pane__name fomio-utility-row__label">{{link.label}}</span>
                </a>
              {{/each}}
            {{else if (eq this.activeMasterContext "bookmarks")}}
              {{#each this.bookmarksLinks as |link|}}
                <a
                  href={{link.href}}
                  class="fomio-master-pane__item fomio-utility-row {{if link.isActive 'is-active'}}"
                  aria-current={{if link.isActive "page"}}
                >
                  <span class="fomio-master-pane__name fomio-utility-row__label">{{link.label}}</span>
                </a>
              {{/each}}
            {{else if (eq this.activeMasterContext "notifications")}}
              {{#each this.notificationsLinks as |link|}}
                <a
                  href={{link.href}}
                  class="fomio-master-pane__item fomio-utility-row {{if link.isActive 'is-active'}}"
                  aria-current={{if link.isActive "page"}}
                >
                  <span class="fomio-master-pane__name fomio-utility-row__label">{{link.label}}</span>
                </a>
              {{/each}}
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
