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
  adminManageUserPathForUser,
  badgesPathForUser,
  invitedPathForUser,
  isAuthPath,
  isMeLandingSurfacePath,
  isOwnUserSummarySurfacePath,
  messagesPathForUser,
  notificationsPathForUser,
  preferencesPathForUser,
  profileSummaryPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import { clearMeHubLandingSession } from "../../lib/fomio-me-hub-landing";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMeHub extends Component {
  @service router;
  @service currentUser;
  @service siteSettings;

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
    return isMeLandingSurfacePath(this.router.currentURL || "", this.currentUser);
  }

  get isLoggedInHub() {
    return Boolean(this.currentUser);
  }

  /**
   * Mirrors `UserController` / `user-nav` gating. Hub only renders on own-profile landing (`viewingSelf`).
   */
  get showActivityTab() {
    const viewingSelf = true;
    return (
      viewingSelf ||
      this.currentUser?.admin ||
      !this.siteSettings?.hide_user_activity_tab
    );
  }

  get showNotificationsTab() {
    const viewingSelf = true;
    return viewingSelf || this.currentUser?.admin;
  }

  get showPrivateMessages() {
    const viewingSelf = true;
    return Boolean(
      this.currentUser?.can_send_private_messages &&
        (viewingSelf || this.currentUser?.admin)
    );
  }

  get canInviteToForum() {
    return Boolean(this.currentUser?.can_invite_to_forum);
  }

  get showBadges() {
    return Boolean(
      this.siteSettings?.enable_badges &&
        (this.currentUser?.badge_count ?? 0) > 0
    );
  }

  get showPreferences() {
    return this.currentUser?.can_edit !== false;
  }

  get showAdminManageUser() {
    return Boolean(this.currentUser?.staff);
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

  get summaryHref() {
    return this.toHubHref(profileSummaryPathForUser(this.currentUser));
  }

  get activityHref() {
    return this.toHubHref(activityPathForUser(this.currentUser));
  }

  get notificationsHref() {
    return this.toHubHref(notificationsPathForUser(this.currentUser));
  }

  get messagesHref() {
    return this.toHubHref(messagesPathForUser(this.currentUser));
  }

  get invitedHref() {
    return this.toHubHref(invitedPathForUser(this.currentUser));
  }

  get badgesHref() {
    return this.toHubHref(badgesPathForUser(this.currentUser));
  }

  get preferencesHref() {
    return this.toHubHref(preferencesPathForUser(this.currentUser));
  }

  get adminManageHref() {
    return this.toHubHref(adminManageUserPathForUser(this.currentUser));
  }

  get aboutHref() {
    return this.toHubHref(aboutPath());
  }

  get logoutHref() {
    return this.toHubHref("/logout");
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

  @action
  signInForMe() {
    redirectToLoginWithIntent("view_profile", this.currentPath);
  }

  @action
  revealNativeProfileSummary(e) {
    if (
      e &&
      (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey || e.button !== 0)
    ) {
      return;
    }
    clearMeHubLandingSession();
    document.body?.classList.remove("fomio-me-hub-landing");
    if (isOwnUserSummarySurfacePath(this.currentPath, this.currentUser)) {
      e?.preventDefault();
    }
  }

  <template>
    {{#if this.shouldRender}}
      {{#if this.isLoggedInHub}}
        <nav class="fomio-me-hub" aria-label={{this.ariaLabel}}>
          {{#if this.summaryHref}}
            <div class="fomio-me-hub__summary">
              <a
                href={{this.summaryHref}}
                class="fomio-me-hub__summary-link"
                {{on "click" this.revealNativeProfileSummary}}
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
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_primary_nav_aria")}}
          >
            <div class="fomio-me-hub__section-body">
              {{#if this.summaryHref}}
                <a
                  class="fomio-me-hub__row"
                  href={{this.summaryHref}}
                  {{on "click" this.revealNativeProfileSummary}}
                >
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "user"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_summary")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}

              {{#if this.showActivityTab}}
                {{#if this.activityHref}}
                  <a class="fomio-me-hub__row" href={{this.activityHref}}>
                    <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                        "bars-staggered"
                      }}</span>
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
              {{/if}}

              {{#if this.showNotificationsTab}}
                {{#if this.notificationsHref}}
                  <a class="fomio-me-hub__row" href={{this.notificationsHref}}>
                    <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                        "bell"
                      }}</span>
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
              {{/if}}

              {{#if this.showPrivateMessages}}
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
              {{/if}}

              {{#if this.canInviteToForum}}
                {{#if this.invitedHref}}
                  <a class="fomio-me-hub__row" href={{this.invitedHref}}>
                    <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                        "user-plus"
                      }}</span>
                    <span class="fomio-me-hub__row-copy">
                      <span class="fomio-me-hub__row-label">{{i18n
                          (themePrefix "mobile_nav.me_hub_invites")
                        }}</span>
                    </span>
                    <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                        "angle-right"
                      }}</span>
                  </a>
                {{/if}}
              {{/if}}

              {{#if this.showBadges}}
                {{#if this.badgesHref}}
                  <a class="fomio-me-hub__row" href={{this.badgesHref}}>
                    <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon
                        "certificate"
                      }}</span>
                    <span class="fomio-me-hub__row-copy">
                      <span class="fomio-me-hub__row-label">{{i18n
                          (themePrefix "mobile_nav.me_hub_badges")
                        }}</span>
                    </span>
                    <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                        "angle-right"
                      }}</span>
                  </a>
                {{/if}}
              {{/if}}

              {{#if this.showPreferences}}
                {{#if this.preferencesHref}}
                  <a class="fomio-me-hub__row" href={{this.preferencesHref}}>
                    <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "gear"}}</span>
                    <span class="fomio-me-hub__row-copy">
                      <span class="fomio-me-hub__row-label">{{i18n
                          (themePrefix "mobile_nav.me_hub_preferences")
                        }}</span>
                    </span>
                    <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                        "angle-right"
                      }}</span>
                  </a>
                {{/if}}
              {{/if}}

              {{#if this.showAdminManageUser}}
                {{#if this.adminManageHref}}
                  <a class="fomio-me-hub__row" href={{this.adminManageHref}}>
                    <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "wrench"}}</span>
                    <span class="fomio-me-hub__row-copy">
                      <span class="fomio-me-hub__row-label">{{i18n
                          (themePrefix "mobile_nav.me_hub_admin")
                        }}</span>
                    </span>
                    <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                        "angle-right"
                      }}</span>
                  </a>
                {{/if}}
              {{/if}}
            </div>
          </section>

          <section
            class="fomio-me-hub__section fomio-me-hub__section--footer"
            aria-label={{i18n (themePrefix "mobile_nav.me_hub_footer_aria")}}
          >
            <div class="fomio-me-hub__section-body">
              {{#if this.aboutHref}}
                <a class="fomio-me-hub__row" href={{this.aboutHref}}>
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "book"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_about")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
              {{#if this.logoutHref}}
                <a
                  class="fomio-me-hub__row fomio-me-hub__row--muted"
                  href={{this.logoutHref}}
                  rel="nofollow"
                >
                  <span class="fomio-me-hub__row-icon" aria-hidden="true">{{icon "sign-out"}}</span>
                  <span class="fomio-me-hub__row-copy">
                    <span class="fomio-me-hub__row-label">{{i18n
                        (themePrefix "mobile_nav.me_hub_sign_out")
                      }}</span>
                  </span>
                  <span class="fomio-me-hub__row-chevron" aria-hidden="true">{{icon
                      "angle-right"
                    }}</span>
                </a>
              {{/if}}
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
