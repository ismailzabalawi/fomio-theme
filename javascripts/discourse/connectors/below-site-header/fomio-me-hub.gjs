import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioAvatar from "../../components/shared/fomio-avatar";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";
import {
  getFomioAuxiliaryMeSections,
  getFomioCoreAccountSections,
} from "../../lib/fomio-account-sections";
import {
  isAuthPath,
  isMeLandingSurfacePath,
} from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMeHub extends Component {
  @service router;
  @service currentUser;
  @service siteSettings;

  @tracked isTouchShell = false;
  @tracked summaryOpen = false;
  @tracked summaryReady = false;
  #unsubscribeTouch = null;
  #summaryObserver = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    this.#summaryObserver?.disconnect();
    this.#summaryObserver = null;
    document.body?.classList.remove("fomio-me-hub-summary-open");
    super.willDestroy();
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    if (!this.isTouchShell || isAuthPath(this.currentPath)) {
      return false;
    }
    return isMeLandingSurfacePath(this.router.currentURL || "", this.currentUser);
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
      label: i18n(themePrefix(section.labelKey)),
      meta: section.metaKey ? i18n(themePrefix(section.metaKey)) : null,
    }));
  }

  get summarySection() {
    return this.coreSections.find((section) => section.key === "summary") ?? null;
  }

  get navigableCoreSections() {
    return this.coreSections.filter((section) => section.key !== "summary");
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

  get displayName() {
    const u = this.currentUser;
    if (!u) {
      return "";
    }
    return (u.name && String(u.name).trim()) || u.username || "";
  }

  get statusLine() {
    const u = this.currentUser;
    if (!u?.username) {
      return null;
    }
    const st = u.status;
    const desc =
      st && typeof st.description === "string" ? st.description.trim() : "";
    if (desc) {
      return desc;
    }
    return `@${u.username}`;
  }

  get ariaLabel() {
    if (this.currentUser) {
      return i18n(themePrefix("mobile_nav.me_hub_aria"));
    }
    return i18n(themePrefix("mobile_nav.me_hub_aria_logged_out"));
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

  #watchForSummaryContent() {
    this.#summaryObserver?.disconnect();
    this.#summaryObserver = new MutationObserver(() => {
      if (document.querySelector(".user-main")) {
        this.summaryReady = true;
        this.#summaryObserver?.disconnect();
        this.#summaryObserver = null;
      }
    });
    this.#summaryObserver.observe(document.body, {
      childList: true,
      subtree: true,
    });
  }

  @action
  signInForMe() {
    redirectToLoginWithIntent("view_profile", this.currentPath);
  }

  @action
  openSummary() {
    this.summaryOpen = true;
    this.summaryReady = Boolean(document.querySelector(".user-main"));
    if (!this.summaryReady) {
      this.#watchForSummaryContent();
    }
    document.body?.classList.add("fomio-me-hub-summary-open");
  }

  @action
  closeSummary() {
    this.#summaryObserver?.disconnect();
    this.#summaryObserver = null;
    this.summaryOpen = false;
    this.summaryReady = false;
    document.body?.classList.remove("fomio-me-hub-summary-open");
  }

  <template>
    {{#if this.shouldRender}}
      {{#if this.isLoggedInHub}}
        {{! Back bar renders as a sibling to <nav>, not inside it.
            Keeps it outside any stacking context the hub creates, so
            position:fixed works correctly against the viewport. }}
        {{#if this.summaryOpen}}
          <div
            class="fomio-me-hub__summary-back-bar"
            role="toolbar"
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_summary_back_bar_aria")}}
          >
            <button
              type="button"
              class="fomio-me-hub__back-btn"
              {{on "click" this.closeSummary}}
            >
              {{icon "chevron-left"}}
              <span>{{i18n (themePrefix "me_stack.back")}}</span>
            </button>
            <span class="fomio-me-hub__summary-panel-title">
              {{i18n (themePrefix "mobile_nav.me_hub_summary")}}
            </span>
          </div>

          {{#unless this.summaryReady}}
            <div class="fomio-me-hub__summary-loading" aria-live="polite" aria-label="Loading…">
              <span class="fomio-me-hub__summary-loading-spinner" aria-hidden="true"></span>
            </div>
          {{/unless}}
        {{/if}}

        <nav
          class="fomio-me-hub {{if this.summaryOpen "fomio-me-hub--summary-open"}}"
          aria-label={{this.ariaLabel}}
        >
          {{#unless this.summaryOpen}}
            {{#if this.summarySection}}
              <div class="fomio-me-hub__summary">
                <button
                  type="button"
                  class="fomio-me-hub__summary-link"
                  {{on "click" this.openSummary}}
                >
                  <span class="fomio-me-hub__summary-avatar" aria-hidden="true">
                    <FomioAvatar @user={{this.currentUser}} @size="lg" />
                  </span>
                  <span class="fomio-me-hub__summary-text">
                    <span class="fomio-me-hub__summary-name">{{this.displayName}}</span>
                    <span class="fomio-me-hub__summary-meta">{{this.statusLine}}</span>
                  </span>
                  <span class="fomio-me-hub__summary-chevron" aria-hidden="true">
                    {{icon "angle-right"}}
                  </span>
                </button>
              </div>
            {{/if}}

          <section
            class="fomio-me-hub__section"
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_primary_nav_aria")}}
          >
            <div class="fomio-me-hub__section-body">
              {{#each this.navigableCoreSections as |section|}}
                {{#if section.isAdminSection}}
                  <hr class="fomio-me-hub__section-divider" aria-hidden="true" />
                {{/if}}
                <a
                  class="fomio-me-hub__row {{if section.isActive "fomio-me-hub__row--active"}}"
                  href={{section.href}}
                >
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon section.icon}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{section.label}}</span>
                    {{#if section.meta}}
                      <span class="fomio-me-hub__row-meta">{{section.meta}}</span>
                    {{/if}}
                  </span>
                  {{#if (this.rowBadge section)}}
                    <span
                      class="fomio-me-hub__row-badge"
                      aria-label="{{this.rowBadge section}} unread"
                    >{{this.rowBadge section}}</span>
                  {{/if}}
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon "angle-right"}}</span>
                </a>
              {{/each}}
            </div>
          </section>

          <section
            class="fomio-me-hub__section fomio-me-hub__section--footer"
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_footer_aria")}}
          >
            <div class="fomio-me-hub__section-body">
              {{#each this.auxiliarySections as |section|}}
                <a
                  class="fomio-me-hub__row {{if section.isMuted "fomio-me-hub__row--muted"}}"
                  href={{section.href}}
                  rel={{section.rel}}
                >
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon section.icon}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{section.label}}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon "angle-right"}}</span>
                </a>
              {{/each}}
            </div>
          </section>
          {{/unless}}
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
