import Component from "@glimmer/component";
import { getOwner } from "@ember/owner";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import getURL from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioPhIcon from "../../components/shared/fomio-ph-icon";
import FomioUserProfileSummary from "../../components/shared/fomio-user-profile-summary";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";
import {
  getFomioAuxiliaryMeSections,
  getFomioCoreAccountSections,
} from "../../lib/fomio-account-sections";
import {
  isFomioShellPath,
  isMeLandingSurfacePath,
} from "../../lib/fomio-mobile-nav-paths";
import { setFomioPreferencesMenuMarker } from "../../lib/fomio-preferences-sections";
import { fomioCurrentPath } from "../../lib/fomio-router-pathname";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMeHub extends Component {
  @service router;
  @service currentUser;
  @service siteSettings;
  @service interfaceColor;

  @tracked isTouchShell = false;
  @tracked isDarkModeActive = false;
  #unsubscribeTouch = null;
  #colorModeObserver = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });
    // html.fomio-color-dark is kept in sync with the active Discourse
    // color scheme by fomio-color-mode.gjs; observing it keeps the switch
    // correct for system-driven changes too, not just taps on this row.
    this.#updateDarkModeState();
    this.#colorModeObserver = new MutationObserver(() => {
      this.#updateDarkModeState();
    });
    this.#colorModeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    this.#colorModeObserver?.disconnect();
    this.#colorModeObserver = null;
    super.willDestroy();
  }

  #updateDarkModeState() {
    if (typeof document === "undefined") {
      return;
    }
    this.isDarkModeActive =
      document.documentElement.classList.contains("fomio-color-dark");
  }

  get darkModeLabel() {
    return i18n(themePrefix("mobile_nav.me_hub_dark_mode"));
  }

  @action
  toggleColorScheme() {
    // Keep the mobile switch binary: off => light, on => dark.
    // Discourse persists the explicit choice through its native
    // interface-color service.
    if (this.isDarkModeActive) {
      this.interfaceColor?.forceLightMode?.();
    } else {
      this.interfaceColor?.forceDarkMode?.();
    }
  }

  get currentPath() {
    return fomioCurrentPath(this.router.currentURL || "");
  }

  get userController() {
    return getOwner(this)?.lookup("controller:user") ?? null;
  }

  get viewedUser() {
    return this.userController?.model ?? this.currentUser ?? null;
  }

  get shouldRender() {
    if (!this.isTouchShell || !isFomioShellPath(this.currentPath)) {
      return false;
    }
    return isMeLandingSurfacePath(this.currentPath, this.currentUser);
  }

  get isLoggedInHub() {
    return Boolean(this.currentUser);
  }

  toHubHref(internalPath) {
    if (
      !internalPath ||
      typeof internalPath !== "string" ||
      !internalPath.startsWith("/")
    ) {
      return null;
    }
    return getURL(internalPath);
  }

  get coreSections() {
    return getFomioCoreAccountSections({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
      siteSettings: this.siteSettings,
    }).map((section) => ({
      ...section,
      href: this.toHubHref(section.href),
      label:
        section.key === "summary"
          ? i18n(themePrefix("mobile_nav.me_hub_summary_child"))
          : i18n(themePrefix(section.labelKey)),
      meta: section.metaKey ? i18n(themePrefix(section.metaKey)) : null,
    }));
  }

  get adminSection() {
    return this.coreSections.find((section) => section.key === "manage-user") ?? null;
  }

  get navigableCoreSections() {
    return this.coreSections.filter((section) => section.key !== "manage-user");
  }

  get auxiliarySections() {
    return getFomioAuxiliaryMeSections({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
      siteSettings: this.siteSettings,
    }).map((section) => ({
      ...section,
      href: this.toHubHref(section.href),
      label: i18n(themePrefix(section.labelKey)),
      rel: section.key === "sign-out" ? "nofollow" : null,
    }));
  }

  get ariaLabel() {
    if (this.currentUser) {
      return i18n(themePrefix("mobile_nav.me_hub_aria"));
    }
    return i18n(themePrefix("mobile_nav.me_hub_aria_logged_out"));
  }

  get summaryEyebrow() {
    return this.viewedUser?.title || null;
  }

  get notificationsUnread() {
    const n = this.currentUser?.unread_notifications;
    if (!n || n <= 0) {
      return null;
    }
    return n > 99 ? "99+" : String(n);
  }

  get messagesUnread() {
    const n = this.currentUser?.unread_private_messages;
    if (!n || n <= 0) {
      return null;
    }
    return n > 99 ? "99+" : String(n);
  }

  get summaryStats() {
    const stats = [];

    if (this.notificationsUnread) {
      stats.push({
        key: "notifications",
        icon: "bell",
        value: this.notificationsUnread,
        label: i18n(themePrefix("mobile_nav.me_hub_notifications")),
      });
    }

    if (this.messagesUnread) {
      stats.push({
        key: "messages",
        icon: "envelope",
        value: this.messagesUnread,
        label: i18n(themePrefix("mobile_nav.me_hub_messages")),
      });
    }

    return stats;
  }

  get adminMarker() {
    if (this.viewedUser?.admin) {
      return "Fomio Admin";
    }

    if (this.viewedUser?.moderator) {
      return "Moderator";
    }

    return null;
  }

  get collapsedInfoState() {
    return this.userController?.collapsedInfoState ?? null;
  }

  get canExpandProfile() {
    return Boolean(this.userController?.canExpandProfile);
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

  get adminActionHref() {
    return this.adminSection?.href ?? null;
  }

  get adminActionLabel() {
    return this.adminSection?.label ?? null;
  }

  get expandedInfoItems() {
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
  rowBadge(section) {
    if (!section?.key) {
      return null;
    }
    if (section.key === "notifications") {
      return this.notificationsUnread;
    }
    if (section.key === "messages") {
      return this.messagesUnread;
    }
    return null;
  }

  @action
  signInForMe() {
    redirectToLoginWithIntent("view_profile", this.currentPath);
  }

  @action
  toggleProfile() {
    this.userController?.toggleProfile?.();
  }

  @action
  openPreferencesMenu(section, event) {
    if (section?.key !== "preferences") {
      return;
    }
    if (event?.metaKey || event?.ctrlKey || event?.shiftKey || event?.altKey) {
      return;
    }

    event?.preventDefault();
    setFomioPreferencesMenuMarker();
    this.router.transitionTo(section.href);
  }

  <template>
    {{#if this.shouldRender}}
      {{#if this.isLoggedInHub}}
        <nav class="fomio-me-hub" aria-label={{this.ariaLabel}}>
          <div class="fomio-me-hub__summary">
            <FomioUserProfileSummary
              @user={{this.viewedUser}}
              @eyebrow={{this.summaryEyebrow}}
              @markerText={{this.adminMarker}}
              @stats={{this.summaryStats}}
              @showExpand={{this.canExpandProfile}}
              @expandButtonLabel={{this.expandButtonLabel}}
              @expandButtonAriaLabel={{this.expandButtonAriaLabel}}
              @expandButtonIcon={{this.expandButtonIcon}}
              @showDetails={{this.showExpandedDetails}}
              @onToggleExpand={{this.toggleProfile}}
              @adminHref={{this.adminActionHref}}
              @adminLabel={{this.adminActionLabel}}
              @detailsItems={{this.expandedInfoItems}}
            />
          </div>

          <section
            class="fomio-me-hub__section"
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_primary_nav_aria")}}
          >
            <div class="fomio-me-hub__section-body fomio-utility-list">
              {{#each this.navigableCoreSections as |section|}}
                {{#if section.isAdminSection}}
                  <hr class="fomio-me-hub__section-divider" aria-hidden="true" />
                {{/if}}
                <a
                  class="fomio-me-hub__row fomio-utility-row {{if section.isActive "fomio-me-hub__row--active is-active"}}"
                  href={{section.href}}
                  {{on "click" (fn this.openPreferencesMenu section)}}
                >
                  <span class="fomio-me-hub__row-icon fomio-utility-row__icon" aria-hidden="true">{{icon section.icon}}</span>
                  <span class="fomio-me-hub__row-copy fomio-utility-row__body">
                    <span class="fomio-me-hub__row-label fomio-utility-row__label">{{section.label}}</span>
                    {{#if section.meta}}
                      <span class="fomio-me-hub__row-meta fomio-utility-row__meta">{{section.meta}}</span>
                    {{/if}}
                  </span>
                  {{#if (this.rowBadge section)}}
                    <span
                      class="fomio-me-hub__row-badge"
                      aria-label="{{this.rowBadge section}} unread"
                    >{{this.rowBadge section}}</span>
                  {{/if}}
                  <span class="fomio-me-hub__row-chevron fomio-utility-row__trailing" aria-hidden="true">{{icon (if (eq section.key "preferences") "angle-up" "angle-right")}}</span>
                </a>
              {{/each}}

              <hr class="fomio-me-hub__section-divider" aria-hidden="true" />
              <button
                type="button"
                class="fomio-me-hub__row fomio-utility-row fomio-me-hub__row--appearance"
                role="switch"
                aria-checked={{if this.isDarkModeActive "true" "false"}}
                {{on "click" this.toggleColorScheme}}
              >
                <span class="fomio-me-hub__row-icon fomio-utility-row__icon" aria-hidden="true">
                  <FomioPhIcon @name="fomio-ph-moon" @size={{18}} />
                </span>
                <span class="fomio-me-hub__row-copy fomio-utility-row__body">
                  <span class="fomio-me-hub__row-label fomio-utility-row__label">{{this.darkModeLabel}}</span>
                </span>
                <span class="fomio-utility-row__trailing" aria-hidden="true">
                  {{! Visual only — the row button carries the switch role.
                      No role attr here, so the fomio-ui-components switch
                      delegation never matches this span. }}
                  <span
                    class="fomio-switch fomio-switch--sm"
                    aria-checked={{if this.isDarkModeActive "true" "false"}}
                  >
                    <span class="fomio-switch__track">
                      <span class="fomio-switch__thumb"></span>
                    </span>
                  </span>
                </span>
              </button>
            </div>
          </section>

          <section
            class="fomio-me-hub__section fomio-me-hub__section--footer"
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_footer_aria")}}
          >
            <div class="fomio-me-hub__section-body fomio-utility-list fomio-utility-list--bare">
              {{#each this.auxiliarySections as |section|}}
                <a
                  class="fomio-me-hub__row fomio-utility-row {{if section.isMuted "fomio-me-hub__row--muted"}}"
                  href={{section.href}}
                  rel={{section.rel}}
                >
                  <span class="fomio-me-hub__row-icon fomio-utility-row__icon" aria-hidden="true">{{icon section.icon}}</span>
                  <span class="fomio-me-hub__row-copy fomio-utility-row__body">
                    <span class="fomio-me-hub__row-label fomio-utility-row__label">{{section.label}}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron fomio-utility-row__trailing" aria-hidden="true">{{icon "angle-right"}}</span>
                </a>
              {{/each}}
            </div>
          </section>
        </nav>
      {{else}}
        <div
          class="fomio-me-hub fomio-me-hub--logged-out"
          role="region"
          aria-label={{this.ariaLabel}}
        >
          <div class="fomio-me-hub__section">
            <div class="fomio-me-hub__section-body fomio-me-hub__section-body--cta">
              <p class="fomio-me-hub__cta-text">{{i18n
                  (themePrefix "mobile_nav.me_hub_sign_in_cta")
                }}</p>
              <button
                type="button"
                class="fomio-me-hub__sign-in-btn"
                {{on "click" this.signInForMe}}
              >
                {{i18n (themePrefix "mobile_nav.me_hub_sign_in")}}
              </button>
              <a href="/signup" class="fomio-me-hub__sign-up-link">
                {{i18n (themePrefix "mobile_nav.me_hub_sign_up")}}
              </a>
            </div>
          </div>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
