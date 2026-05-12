import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
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

const CORE_NOTIFICATIONS_NAV_SUBSTR = "user-nav__notifications-";

/**
 * Fomio second-level nav for Discourse user notifications (Phase M2-B).
 * H6-A: touch + user-shell Option 3 uses grouped disclosure (H5) above the active
 * route card; canonical links and plugin mirroring only. Native dismiss, stream, and
 * routes stay in Discourse.
 */
export default class FomioNotificationsSectionMenu extends Component {
  @service router;
  @service site;
  @service siteSettings;

  @tracked insertion = null;
  @tracked notificationsLayoutVariant = "legacy";
  @tracked pluginRows = [];
  /** When false, accordion follows `activeGroupId` from the URL. */
  @tracked disclosureUserOverride = false;
  /** Expanded panel when `disclosureUserOverride` is true; null = all collapsed. */
  @tracked disclosureExpandedId = null;

  _onRouteDidChange = () => {
    this.disclosureUserOverride = false;
    this.disclosureExpandedId = null;
    this.insertion = null;
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

  get hasMirroredPlugins() {
    return this.pluginRows.length > 0;
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

  normalizePathForCompare(href) {
    try {
      const u = new URL(href, window.location.origin);
      return u.pathname;
    } catch {
      return href.split("?")[0];
    }
  }

  isActivePath(fullPath) {
    return fomioPathsEqual(this.pathNoQuery, fullPath);
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

  get allNavRows() {
    const plugins = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));
    return [...this.coreRows, ...plugins];
  }

  /** Legacy flat list + active card source. */
  get rows() {
    return this.allNavRows;
  }

  get activeRow() {
    return this.allNavRows.find((r) => r.isActive) ?? null;
  }

  get inactiveRows() {
    return this.rows.filter((r) => !r.isActive);
  }

  rowGroupId(rowId) {
    if (String(rowId).startsWith("plugin-")) {
      return "more";
    }
    switch (rowId) {
      case "all":
        return "all";
      case "responses":
      case "mentions":
        return "conversations";
      case "likes-received":
      case "links":
        return "engagement";
      case "edits":
        return "changes";
      default:
        return "more";
    }
  }

  get activeGroupId() {
    const row = this.activeRow;
    if (!row) {
      return "all";
    }
    return this.rowGroupId(row.id);
  }

  get openDisclosureGroupId() {
    if (!this.disclosureUserOverride) {
      return this.activeGroupId;
    }
    return this.disclosureExpandedId;
  }

  get disclosureGroups() {
    const base = this.basePath;
    if (!base) {
      return [];
    }

    const rowById = new Map(this.coreRows.map((r) => [r.id, r]));

    const mk = (id, labelKey, rowIds) => {
      const rows = rowIds
        .map((rid) => rowById.get(rid))
        .filter(Boolean);
      return {
        id,
        label: i18n(themePrefix(labelKey)),
        panelId: `fomio-notifications-panel-${id}`,
        triggerId: `fomio-notifications-trigger-${id}`,
        rows,
      };
    };

    const groups = [
      mk("all", "notifications_submenu.group_all", ["all"]),
      mk("conversations", "notifications_submenu.group_conversations", [
        "responses",
        ...(this.siteSettings.enable_mentions ? ["mentions"] : []),
      ]),
      mk("engagement", "notifications_submenu.group_engagement", [
        "likes-received",
        "links",
      ]),
      mk("changes", "notifications_submenu.group_changes", ["edits"]),
    ];

    const moreRows = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));

    if (moreRows.length > 0) {
      groups.push({
        id: "more",
        label: i18n(themePrefix("notifications_submenu.group_more")),
        panelId: "fomio-notifications-panel-more",
        triggerId: "fomio-notifications-trigger-more",
        rows: moreRows,
      });
    }

    return groups;
  }

  extractPluginRows(horiz) {
    const pills = horiz.querySelectorAll("ul.nav-pills > li");
    const out = [];
    pills.forEach((li, index) => {
      const cls = li.className?.toString() ?? "";
      if (cls.includes(CORE_NOTIFICATIONS_NAV_SUBSTR)) {
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
  toggleDisclosureGroup(groupId) {
    const cur = this.openDisclosureGroupId;
    this.disclosureUserOverride = true;
    if (cur === groupId) {
      this.disclosureExpandedId = null;
    } else {
      this.disclosureExpandedId = groupId;
    }
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
        if (this.insertion) {
          this.insertion = null;
          this.notificationsLayoutVariant = "legacy";
        }
        this.pluginRows = [];
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
        this.pluginRows = this.extractPluginRows(horiz);
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
            class="fomio-notifications-section-menu fomio-notifications-section-menu--option3-head fomio-notifications-section-menu--disclosure fomio-section-menu--expanded-shell {{if
              this.hasMirroredPlugins
              'fomio-notifications-section-menu--mirrored-plugins'
            }}"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-notifications-section-menu__title">{{this.sectionTitle}}</h2>
            <div class="fomio-notifications-disclosure">
              {{#each this.disclosureGroups as |g|}}
                <div class="fomio-notifications-disclosure__group">
                  <button
                    id={{g.triggerId}}
                    type="button"
                    class="fomio-notifications-disclosure__header {{if
                      (eq g.id this.activeGroupId)
                      'fomio-notifications-disclosure__header--active-group'
                    }}"
                    aria-expanded={{if (eq this.openDisclosureGroupId g.id) "true" "false"}}
                    aria-controls={{g.panelId}}
                    {{on "click" (fn this.toggleDisclosureGroup g.id)}}
                  >
                    {{g.label}}
                  </button>
                  <div
                    id={{g.panelId}}
                    class="fomio-notifications-disclosure__panel"
                    role="region"
                    aria-labelledby={{g.triggerId}}
                    hidden={{if (eq this.openDisclosureGroupId g.id) false true}}
                  >
                    <ul class="fomio-notifications-section-menu__list">
                      {{#each g.rows as |row|}}
                        <li class="fomio-notifications-disclosure__item">
                          <a
                            href={{row.href}}
                            class="fomio-notifications-section-menu__link {{if
                              row.isActive
                              'is-active'
                            }}"
                            aria-current={{if row.isActive "page"}}
                          >
                            {{row.label}}
                          </a>
                        </li>
                      {{/each}}
                    </ul>
                  </div>
                </div>
              {{/each}}
            </div>
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
            class="fomio-notifications-section-menu fomio-section-menu--expanded-shell {{if
              this.hasMirroredPlugins
              'fomio-notifications-section-menu--mirrored-plugins'
            }}"
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
  </template>
}
