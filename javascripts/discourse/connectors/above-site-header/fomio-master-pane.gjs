import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { buildFomioHubCatalog } from "../../lib/fomio-hub-catalog";
import { isFomioShellPath } from "../../lib/fomio-mobile-nav-paths";
import {
  clearPendingMasterPaneOverlay,
  PENDING_MASTER_PANE_OVERLAY_KEY,
} from "../../lib/fomio-master-pane-overlay-state";
const MASTER_PANE_CONTEXTS = ["hubs"];

export default class FomioMasterPane extends Component {
  @service router;
  @service site;
  @service currentUser;
  @service siteSettings;

  @tracked overlayOpen = false;
  @tracked overlayContext = null;
  @tracked hubExpansionState = {};

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
    return this.shouldRenderMasterPane;
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
    const overlayOpen = this.shouldRenderMasterPane;

    document.body.classList.toggle(
      "fomio-master-pane-rail-open",
      overlayOpen
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
    return i18n(themePrefix("hubs_index.title"));
  }

  get descriptionLabel() {
    return i18n(themePrefix("hubs_index.description"));
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
          <header class="fomio-master-pane__header">
            <h2 class="fomio-master-pane__title">{{this.titleLabel}}</h2>
            <p class="fomio-master-pane__description">{{this.descriptionLabel}}</p>
          </header>

          <nav
            class="fomio-master-pane__nav fomio-utility-list fomio-utility-list--bare"
            aria-label={{this.titleLabel}}
            {{on "click" this.handleNavClick}}
          >
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
          </nav>
        </div>
      </aside>
    {{/if}}
  </template>
}
