import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import avatar from "discourse/helpers/avatar";
import icon from "discourse/helpers/d-icon";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";
import {
  aboutPath,
  activityPathForUser,
  bookmarksPathForUser,
  isAuthPath,
  isMeHubSurfacePath,
  messagesPathForUser,
  notificationsPathForUser,
  preferencesPathForUser,
  profileSummaryPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMeHub extends Component {
  @service router;
  @service currentUser;

  @tracked isTouchShell = false;
  #unsubscribeTouch = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    super.willDestroy();
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    if (!this.isTouchShell || isAuthPath(this.currentPath)) {
      return false;
    }
    return isMeHubSurfacePath(this.currentPath, this.currentUser);
  }

  get isLoggedInHub() {
    return Boolean(this.currentUser);
  }

  /**
   * Subfolder-safe document URL for Account group + summary (Phase 3C-1).
   * Returns null if path invalid — omit chevron row.
   */
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

  get profileSummaryHref() {
    return this.toHubHref(profileSummaryPathForUser(this.currentUser));
  }

  get activityHref() {
    return this.toHubHref(activityPathForUser(this.currentUser));
  }

  get bookmarksHref() {
    return this.toHubHref(bookmarksPathForUser(this.currentUser));
  }

  get messagesHref() {
    return this.toHubHref(messagesPathForUser(this.currentUser));
  }

  get preferencesHref() {
    return this.toHubHref(preferencesPathForUser(this.currentUser));
  }

  get notificationsHref() {
    return this.toHubHref(notificationsPathForUser(this.currentUser));
  }

  get aboutHref() {
    return this.toHubHref(aboutPath());
  }

  get logoutUrl() {
    return "/logout";
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

  get sessionSectionLabel() {
    return i18n(themePrefix("mobile_nav.me_hub_section_session"));
  }

  get ariaLabel() {
    if (this.currentUser) {
      return i18n(themePrefix("mobile_nav.me_hub_aria"));
    }
    return i18n(themePrefix("mobile_nav.me_hub_aria_logged_out"));
  }

  @action
  signInForMe() {
    redirectToLoginWithIntent("view_profile", this.currentPath);
  }

  <template>
    {{#if this.shouldRender}}
      {{#if this.isLoggedInHub}}
        <nav class="fomio-me-hub" aria-label={{this.ariaLabel}}>
          {{#if this.profileSummaryHref}}
            <div class="fomio-me-hub__summary">
              <a
                href={{this.profileSummaryHref}}
                class="fomio-me-hub__summary-link"
              >
                <span class="fomio-me-hub__summary-avatar" aria-hidden="true">
                  {{avatar this.currentUser imageSize="large"}}
                </span>
                <span class="fomio-me-hub__summary-text">
                  <span class="fomio-me-hub__summary-name">{{this.displayName}}</span>
                  <span class="fomio-me-hub__summary-meta">{{this.statusLine}}</span>
                </span>
                <span class="fomio-me-hub__summary-chevron" aria-hidden="true">{{icon
                    "angle-right"
                  }}</span>
              </a>
            </div>
          {{/if}}

          <section
            class="fomio-me-hub__section"
            aria-labelledby="fomio-me-hub-account-heading"
          >
            <h2 id="fomio-me-hub-account-heading" class="fomio-me-hub__section-title">
              {{i18n (themePrefix "mobile_nav.me_hub_section_account")}}
            </h2>
            <div class="fomio-me-hub__section-body">
              {{#if this.profileSummaryHref}}
                <a class="fomio-me-hub__row" href={{this.profileSummaryHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "user"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_profile")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
              {{#if this.activityHref}}
                <a class="fomio-me-hub__row" href={{this.activityHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "list"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_activity")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
              {{#if this.bookmarksHref}}
                <a class="fomio-me-hub__row" href={{this.bookmarksHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                      "bookmark"
                    }}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_saved")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
              {{#if this.messagesHref}}
                <a class="fomio-me-hub__row" href={{this.messagesHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                      "envelope"
                    }}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_messages")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
            </div>
          </section>

          <section
            class="fomio-me-hub__section"
            aria-labelledby="fomio-me-hub-prefs-heading"
          >
            <h2 id="fomio-me-hub-prefs-heading" class="fomio-me-hub__section-title">
              {{i18n (themePrefix "mobile_nav.me_hub_section_preferences")}}
            </h2>
            <div class="fomio-me-hub__section-body">
              {{#if this.preferencesHref}}
                <a class="fomio-me-hub__row" href={{this.preferencesHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "gear"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_settings")
                      }}</span>
                    <span class="fomio-me-hub__row-meta">{{i18n
                        (themePrefix "mobile_nav.me_hub_settings_meta")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
              {{#if this.notificationsHref}}
                <a class="fomio-me-hub__row" href={{this.notificationsHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "bell"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_notifications")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
            </div>
          </section>

          {{#if this.aboutHref}}
            <section
              class="fomio-me-hub__section"
              aria-labelledby="fomio-me-hub-support-heading"
            >
              <h2 id="fomio-me-hub-support-heading" class="fomio-me-hub__section-title">
                {{i18n (themePrefix "mobile_nav.me_hub_section_support")}}
              </h2>
              <div class="fomio-me-hub__section-body">
                <a class="fomio-me-hub__row" href={{this.aboutHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                      "book"
                    }}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_about")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              </div>
            </section>
          {{/if}}

          <section
            class="fomio-me-hub__section fomio-me-hub__section--footer"
            aria-label={{this.sessionSectionLabel}}
          >
            <div class="fomio-me-hub__section-body">
              <a
                class="fomio-me-hub__row fomio-me-hub__row--muted"
                href={{this.logoutUrl}}
                rel="nofollow"
              >
                <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                    "sign-out"
                  }}</span>
                <span class="fomio-me-hub__row-copy">
                  <span class="fomio-me-hub__row-label">{{i18n
                      (themePrefix "mobile_nav.me_hub_sign_out")
                    }}</span>
                </span>
                <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                    "angle-right"
                  }}</span>
              </a>
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
            </div>
          </div>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
