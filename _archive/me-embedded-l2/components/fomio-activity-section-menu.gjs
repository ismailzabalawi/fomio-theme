import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { and, eq } from "discourse/truth-helpers";
import { themePrefix } from "virtual:theme";
import {
  fomioPathnameNoQuery,
  fomioPathsEqual,
} from "../lib/fomio-router-pathname";

const CORE_ACTIVITY_NAV_CLASS = "user-nav__activity-";

/**
 * Fomio second-level nav for Discourse user activity (Phase M2-C).
 * Phase H4-F (touch): inactive filters in the nav `in-element`; active card uses
 * `activeCardPortal = { parent: wrapper }` with `insertBefore=null` (append). Visual order
 * (nav → active card → stream) is enforced via flex `order` on `.new-user-content-wrapper`.
 * (No post-stream inactive tail — unlike Notifications/Invites Option 3.)
 */
export default class FomioActivitySectionMenu extends Component {
  @service router;
  @service currentUser;

  @tracked insertion = null;
  /** When set, append-only target for `.fomio-activity-option3-active-card` (wrapper). */
  @tracked activeCardPortal = null;
  @tracked activityLayoutVariant = "legacy";
  @tracked pluginRows = [];

  _onRouteDidChange = () => {
    this.insertion = null;
    this.activeCardPortal = null;
    this.activityLayoutVariant = "legacy";
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

  get userController() {
    return getOwner(this).lookup("controller:user");
  }

  get profileUser() {
    return this.userController?.model;
  }

  get username() {
    const m = /^\/u\/([^/]+)\/activity/.exec(this.pathNoQuery);
    return m ? decodeURIComponent(m[1]) : null;
  }

  get basePath() {
    const u = this.username;
    return u ? `/u/${u}/activity` : null;
  }

  get sectionTitle() {
    return i18n("user.activity_stream");
  }

  get navAriaLabel() {
    return i18n(themePrefix("activity_submenu.nav_aria"));
  }

  get hasMirroredPlugins() {
    return this.pluginRows.length > 0;
  }

  get showRead() {
    return Boolean(this.userController?.showRead);
  }

  get showDrafts() {
    return Boolean(this.userController?.showDrafts);
  }

  get showBookmarks() {
    return Boolean(this.userController?.showBookmarks);
  }

  get pendingCount() {
    const m = this.profileUser;
    if (!m) {
      return 0;
    }
    const n = m.pending_posts_count ?? m.pendingPostsCount;
    return Number(n) || 0;
  }

  get draftLabel() {
    return this.currentUser?.draft_count > 0
      ? i18n("drafts.label_with_count", {
          count: this.currentUser.draft_count,
        })
      : i18n("drafts.label");
  }

  get pendingLabel() {
    return this.pendingCount > 0
      ? i18n("pending_posts.label_with_count", {
          count: this.pendingCount,
        })
      : i18n("pending_posts.label");
  }

  isActivePath(fullPath) {
    return fomioPathsEqual(this.pathNoQuery, fullPath);
  }

  isActiveForPath(suffix) {
    const base = this.basePath;
    if (!base) {
      return false;
    }
    if (suffix === "") {
      return this.isActivePath(base);
    }
    return this.isActivePath(`${base}/${suffix}`);
  }

  extractPluginRows(horiz) {
    const pills = horiz.querySelectorAll("ul.nav-pills > li");
    const out = [];
    pills.forEach((li, index) => {
      const cls = li.className?.toString() ?? "";
      if (cls.includes(CORE_ACTIVITY_NAV_CLASS)) {
        return;
      }
      const a = li.querySelector("a[href]");
      if (!a) {
        return;
      }
      const rawHref = a.getAttribute("href");
      const label = (a.textContent || "").trim().replace(/\s+/g, " ");
      if (!rawHref || !label) {
        return;
      }
      const href = getURL(rawHref);
      out.push({
        id: `plugin-${index}-${href}`,
        href,
        label,
      });
    });
    return out;
  }

  normalizePathForCompare(href) {
    try {
      const u = new URL(href, window.location.origin);
      return u.pathname;
    } catch {
      return href.split("?")[0];
    }
  }

  get coreRows() {
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
        id: "topics",
        href: getURL(`${base}/topics`),
        label: i18n("user_action_groups.4"),
        isActive: this.isActiveForPath("topics"),
      },
      {
        id: "replies",
        href: getURL(`${base}/replies`),
        label: i18n("user_action_groups.5"),
        isActive: this.isActiveForPath("replies"),
      },
    ];

    if (this.showRead) {
      out.push({
        id: "read",
        href: getURL(`${base}/read`),
        label: i18n("user.read"),
        isActive: this.isActiveForPath("read"),
      });
    }

    if (this.showDrafts) {
      out.push({
        id: "drafts",
        href: getURL(`${base}/drafts`),
        label: this.draftLabel,
        isActive: this.isActiveForPath("drafts"),
      });
    }

    if (this.pendingCount > 0) {
      out.push({
        id: "pending",
        href: getURL(`${base}/pending`),
        label: this.pendingLabel,
        isActive: this.isActiveForPath("pending"),
      });
    }

    out.push({
      id: "likes",
      href: getURL(`${base}/likes-given`),
      label: i18n("user_action_groups.1"),
      isActive: this.isActiveForPath("likes-given"),
    });

    if (this.showBookmarks) {
      out.push({
        id: "bookmarks",
        href: getURL(`${base}/bookmarks`),
        label: i18n("user_action_groups.3"),
        isActive: this.isActiveForPath("bookmarks"),
      });
    }

    return out;
  }

  get rows() {
    const plugins = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));
    return [...this.coreRows, ...plugins];
  }

  get inactiveRows() {
    return this.rows.filter((r) => !r.isActive);
  }

  /** Phase M2-H2 / H4-F: canonical active row for card header link. */
  get activeRow() {
    return this.rows.find((r) => r.isActive) ?? null;
  }

  @action
  scheduleInsertion() {
    let attempts = 0;
    const maxAttempts = 36;

    const tryRun = () => {
      const url = fomioPathnameNoQuery(this.router.currentURL);
      const onActivityRoute =
        /^\/u\/[^/]+\/activity(\/|$)/.test(url) ||
        (this.router.currentRouteName || "").startsWith("userActivity.");

      if (!onActivityRoute) {
        if (this.insertion || this.activeCardPortal) {
          this.insertion = null;
          this.activeCardPortal = null;
          this.activityLayoutVariant = "legacy";
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

      const touch = document.body.classList.contains("fomio-surface-touch");
      const useOption3 = touch;

      if (useOption3 && (!wrapper || !nav || !horiz) && attempts < maxAttempts) {
        attempts += 1;
        requestAnimationFrame(tryRun);
        return;
      }

      if (nav && horiz) {
        this.activityLayoutVariant = useOption3 ? "activityOption3" : "legacy";
        this.insertion = { parent: nav };
        this.pluginRows = this.extractPluginRows(horiz);
        this.activeCardPortal =
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
      class="fomio-activity-section-menu__host"
      aria-hidden="true"
    ></span>
    {{#if (and this.insertion this.username)}}
      {{#in-element this.insertion.parent insertBefore=null}}
        {{#if (eq this.activityLayoutVariant "activityOption3")}}
          <nav
            class="fomio-activity-section-menu fomio-activity-section-menu--option3-head fomio-section-menu--expanded-shell {{if
              this.hasMirroredPlugins
              'fomio-activity-section-menu--mirrored-plugins'
            }}"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-activity-section-menu__title">{{this.sectionTitle}}</h2>
            <ul class="fomio-activity-section-menu__list">
              {{#each this.inactiveRows as |row|}}
                <li class="fomio-activity-section-menu__item">
                  <a
                    href={{row.href}}
                    class="fomio-activity-section-menu__link"
                  >
                    {{row.label}}
                  </a>
                </li>
              {{/each}}
            </ul>
          </nav>
        {{else}}
          <nav
            class="fomio-activity-section-menu fomio-section-menu--expanded-shell {{if
              this.hasMirroredPlugins
              'fomio-activity-section-menu--mirrored-plugins'
            }}"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-activity-section-menu__title">{{this.sectionTitle}}</h2>
            <ul class="fomio-activity-section-menu__list">
              {{#each this.rows as |row|}}
                <li
                  class="fomio-activity-section-menu__item {{if
                    row.isActive
                    'fomio-section-menu__item--h2-active-card-source'
                  }}"
                >
                  <a
                    href={{row.href}}
                    class="fomio-activity-section-menu__link {{if row.isActive 'is-active'}}"
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
        this.activeCardPortal
        this.activeRow
        (eq this.activityLayoutVariant "activityOption3")
      )
    }}
      {{#in-element this.activeCardPortal.parent insertBefore=null}}
        <div
          class="fomio-activity-option3-active-card fomio-section-menu__active-card"
        >
          <a
            href={{this.activeRow.href}}
            class="fomio-section-menu__active-card-link"
            aria-current="page"
          >{{this.activeRow.label}}</a>
        </div>
      {{/in-element}}
    {{/if}}
  </template>
}
