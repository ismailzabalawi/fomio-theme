import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { and, eq, gt } from "discourse/truth-helpers";
import { themePrefix } from "virtual:theme";
import {
  fomioPathnameNoQuery,
  fomioPathsEqual,
} from "../lib/fomio-router-pathname";

/**
 * Fomio second-level nav for Discourse user notifications (Phase M2-B).
 * Phase H4-D: when the user-shell plugin decorates the wrapper and the surface is
 * touch, inactive filter rows render after native `[data-fomio-user-content]` so the
 * active filter reads as an opened card with leaf content inside, then other filters.
 * Native dismiss controls and plugin `user-notifications-bottom` rows stay in core DOM.
 */
export default class FomioNotificationsSectionMenu extends Component {
  @service router;
  @service site;
  @service siteSettings;

  @tracked insertion = null;
  @tracked insertionAfterContent = null;
  @tracked notificationsLayoutVariant = "legacy";

  _onRouteDidChange = () => {
    this.insertion = null;
    this.insertionAfterContent = null;
    this.notificationsLayoutVariant = "legacy";
    this.scheduleInsertion();
  };

  constructor() {
    super(...arguments);
    this.router.on("routeDidChange", this._onRouteDidChange);
  }

  willDestroy() {
    super.willDestroy();
    this.router.off("routeDidChange", this._onRouteDidChange);
  }

  get pathNoQuery() {
    return fomioPathnameNoQuery(this.router.currentURL);
  }

  get username() {
    const m = /^\/u\/([^/]+)\/notifications/.exec(this.pathNoQuery);
    if (m) {
      return decodeURIComponent(m[1]);
    }
    if (
      this.pathNoQuery === "/notifications" ||
      this.pathNoQuery.startsWith("/notifications/")
    ) {
      return this.args.usernameFallback ?? null;
    }
    return null;
  }

  get basePath() {
    const u = this.username;
    return u ? `/u/${u}/notifications` : null;
  }

  get sectionTitle() {
    return i18n("user.notifications");
  }

  get navAriaLabel() {
    return i18n(themePrefix("notifications_submenu.nav_aria"));
  }

  get inactiveTailAriaLabel() {
    return i18n(themePrefix("notifications_submenu.inactive_aria"));
  }

  isActiveForPath(suffix) {
    const base = this.basePath;
    if (!base) {
      return false;
    }
    if (suffix === "") {
      return fomioPathsEqual(this.pathNoQuery, base);
    }
    return fomioPathsEqual(this.pathNoQuery, `${base}/${suffix}`);
  }

  get rows() {
    const base = this.basePath;
    if (!base) {
      return [];
    }

    const out = [
      {
        id: "all",
        href: getURL(base),
        label: i18n("user.filters.all"),
        isActive: this.isActiveForPath(""),
      },
      {
        id: "responses",
        href: getURL(`${base}/responses`),
        label: i18n("user_action_groups.5"),
        isActive: this.isActiveForPath("responses"),
      },
      {
        id: "likes-received",
        href: getURL(`${base}/likes-received`),
        label: i18n("user_action_groups.2"),
        isActive: this.isActiveForPath("likes-received"),
      },
    ];

    if (this.siteSettings.enable_mentions) {
      out.push({
        id: "mentions",
        href: getURL(`${base}/mentions`),
        label: i18n("user_action_groups.7"),
        isActive: this.isActiveForPath("mentions"),
      });
    }

    out.push(
      {
        id: "edits",
        href: getURL(`${base}/edits`),
        label: i18n("user_action_groups.11"),
        isActive: this.isActiveForPath("edits"),
      },
      {
        id: "links",
        href: getURL(`${base}/links`),
        label: i18n("user_action_groups.17"),
        isActive: this.isActiveForPath("links"),
      }
    );

    return out;
  }

  get activeRow() {
    return this.rows.find((r) => r.isActive) ?? null;
  }

  get inactiveRows() {
    return this.rows.filter((r) => !r.isActive);
  }

  get pluginWillDecorateShell() {
    if (!this.siteSettings.fomio_user_shell_enabled) {
      return false;
    }
    if (
      this.siteSettings.fomio_user_shell_mobile_only &&
      !this.site.mobileView
    ) {
      return false;
    }
    return true;
  }

  @action
  scheduleInsertion() {
    let attempts = 0;
    const maxAttempts = 36;

    const tryRun = () => {
      const url = fomioPathnameNoQuery(this.router.currentURL);
      const onNotificationsRoute =
        /^\/u\/[^/]+\/notifications(\/|$)/.test(url) ||
        url === "/notifications" ||
        url.startsWith("/notifications/") ||
        (this.router.currentRouteName || "").startsWith("userNotifications.");

      if (!onNotificationsRoute) {
        if (this.insertion || this.insertionAfterContent) {
          this.insertion = null;
          this.insertionAfterContent = null;
          this.notificationsLayoutVariant = "legacy";
        }
        return;
      }

      const nav = document.querySelector(
        "#main-outlet .user-main .user-navigation.user-navigation-secondary"
      );
      const horiz = nav?.querySelector(":scope > nav.horizontal-overflow-nav");
      const wrapper = document.querySelector(
        "#main-outlet .user-main .new-user-content-wrapper"
      );

      const shellReady =
        wrapper?.dataset?.fomioUserShell === "true" &&
        wrapper?.dataset?.fomioUserSection === "notifications";

      const touch = document.body.classList.contains("fomio-surface-touch");
      const waitForShellContract =
        touch &&
        this.pluginWillDecorateShell &&
        !shellReady &&
        attempts < maxAttempts;

      if (waitForShellContract) {
        attempts += 1;
        requestAnimationFrame(tryRun);
        return;
      }

      const useOption3 = touch && shellReady;

      if (nav && horiz) {
        this.notificationsLayoutVariant = useOption3 ? "option3" : "legacy";
        this.insertion = { parent: nav };
        this.insertionAfterContent =
          useOption3 && wrapper ? { parent: wrapper } : null;
        return;
      }
      attempts += 1;
      if (attempts < maxAttempts) {
        requestAnimationFrame(tryRun);
      }
    };

    requestAnimationFrame(tryRun);
  }

  <template>
    <span
      {{didInsert this.scheduleInsertion}}
      class="fomio-notifications-section-menu__host"
      aria-hidden="true"
    ></span>
    {{#if (and this.insertion this.username)}}
      {{#in-element this.insertion.parent insertBefore=null}}
        {{#if (eq this.notificationsLayoutVariant "option3")}}
          <nav
            class="fomio-notifications-section-menu fomio-notifications-section-menu--option3-head fomio-section-menu--expanded-shell"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-notifications-section-menu__title">{{this.sectionTitle}}</h2>
            {{#if this.activeRow}}
              <div class="fomio-section-menu__active-card">
                <a
                  href={{this.activeRow.href}}
                  class="fomio-section-menu__active-card-link"
                  aria-current="page"
                >{{this.activeRow.label}}</a>
              </div>
            {{/if}}
          </nav>
        {{else}}
          <nav
            class="fomio-notifications-section-menu fomio-section-menu--expanded-shell"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-notifications-section-menu__title">{{this.sectionTitle}}</h2>
            <ul class="fomio-notifications-section-menu__list">
              {{#each this.rows as |row|}}
                <li
                  class="fomio-notifications-section-menu__item {{if
                    row.isActive
                    'fomio-section-menu__item--h2-active-card-source'
                  }}"
                >
                  <a
                    href={{row.href}}
                    class="fomio-notifications-section-menu__link {{if row.isActive 'is-active'}}"
                    aria-current={{if row.isActive "page"}}
                  >
                    {{row.label}}
                  </a>
                </li>
              {{/each}}
            </ul>
            {{#if this.activeRow}}
              <div class="fomio-section-menu__active-card">
                <a
                  href={{this.activeRow.href}}
                  class="fomio-section-menu__active-card-link"
                  aria-current="page"
                >{{this.activeRow.label}}</a>
              </div>
            {{/if}}
          </nav>
        {{/if}}
      {{/in-element}}
    {{/if}}
    {{#if
      (and
        (eq this.notificationsLayoutVariant "option3")
        this.insertionAfterContent
        (gt this.inactiveRows.length 0)
      )
    }}
      {{#in-element this.insertionAfterContent.parent insertBefore=null}}
        <ul
          class="fomio-notifications-section-menu__list fomio-notifications-section-menu__inactive-tail"
          aria-label={{this.inactiveTailAriaLabel}}
        >
          {{#each this.inactiveRows as |row|}}
            <li class="fomio-notifications-section-menu__item">
              <a
                href={{row.href}}
                class="fomio-notifications-section-menu__link"
              >
                {{row.label}}
              </a>
            </li>
          {{/each}}
        </ul>
      {{/in-element}}
    {{/if}}
  </template>
}
