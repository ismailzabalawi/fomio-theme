import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { and } from "discourse/truth-helpers";
import { themePrefix } from "virtual:theme";
import {
  fomioPathnameNoQuery,
  fomioPathsEqual,
} from "../lib/fomio-router-pathname";

/**
 * Fomio second-level nav for Discourse user notifications (Phase M2-B).
 * Ember 6+ `{{#in-element}}` only allows `insertBefore=null` (append to parent). We append
 * into `.user-navigation-secondary` and rely on flex `order: -1` to sit above native pills.
 */
export default class FomioNotificationsSectionMenu extends Component {
  @service router;
  @service siteSettings;

  @tracked insertion = null;

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

  /** Phase M2-H2: duplicate active row as card header on mobile (CSS hides list source). */
  get activeRow() {
    return this.rows.find((r) => r.isActive) ?? null;
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
        return;
      }

      const nav = document.querySelector(
        "#main-outlet .user-main .user-navigation.user-navigation-secondary"
      );
      const horiz = nav?.querySelector(":scope > nav.horizontal-overflow-nav");
      if (nav && horiz) {
        this.insertion = { parent: nav };
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
      {{/in-element}}
    {{/if}}
  </template>
}
