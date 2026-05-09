import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
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

const CORE_PREFERENCE_NAV_CLASSES = new Set([
  "user-nav__preferences-account",
  "user-nav__preferences-security",
  "user-nav__preferences-profile",
  "user-nav__preferences-emails",
  "user-nav__preferences-notifications",
  "user-nav__preferences-tracking",
  "user-nav__preferences-users",
  "user-nav__preferences-interface",
  "user-nav__preferences-navigation-menu",
]);

function isCorePreferenceLi(li) {
  for (const c of li.classList) {
    if (CORE_PREFERENCE_NAV_CLASSES.has(c)) {
      return true;
    }
  }
  return false;
}

/**
 * Fomio second-level nav for Discourse user preferences (Phase M2-D).
 * Same insertion pattern as notifications/activity: `in-element` append + flex order -1.
 * Core nav classes are matched explicitly so plugin rows like `user-nav__preferences-chat` can be detected.
 */
export default class FomioPreferencesSectionMenu extends Component {
  @service router;
  @service currentUser;

  @tracked insertion = null;
  @tracked pluginRows = [];

  get pathNoQuery() {
    return fomioPathnameNoQuery(this.router.currentURL);
  }

  /** Active-state only: self-serve `/u/:username/preferences/…` ↔ `/my/preferences/…`. */
  get preferencesActivePath() {
    const p = this.pathNoQuery;
    const username = this.currentUser?.username;
    if (!username) {
      return p;
    }
    const re = new RegExp(
      `^/u/${username.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}/preferences(?=/|$)`,
      "i"
    );
    if (!re.test(p)) {
      return p;
    }
    return p.replace(re, "/my/preferences");
  }

  get preferencesController() {
    return getOwner(this).lookup("controller:preferences");
  }

  get canChangeTrackingPreferences() {
    return Boolean(
      this.preferencesController?.model?.can_change_tracking_preferences
    );
  }

  get basePath() {
    return "/my/preferences";
  }

  get sectionTitle() {
    return i18n("user.preferences.title");
  }

  get navAriaLabel() {
    return i18n(themePrefix("preferences_submenu.nav_aria"));
  }

  get hasMirroredPlugins() {
    return this.pluginRows.length > 0;
  }

  isActivePath(fullPath) {
    return fomioPathsEqual(this.preferencesActivePath, fullPath);
  }

  isActiveAccount() {
    const ac = this.preferencesActivePath;
    return (
      fomioPathsEqual(ac, "/my/preferences") ||
      fomioPathsEqual(ac, "/my/preferences/account")
    );
  }

  isActiveSegment(segment) {
    return this.isActivePath(`${this.basePath}/${segment}`);
  }

  extractPluginRows(horiz) {
    const ul = horiz.querySelector("ul.nav-pills");
    if (!ul) {
      return [];
    }
    const pills = ul.querySelectorAll(":scope li");
    const out = [];
    const seen = new Set();
    pills.forEach((li, index) => {
      if (isCorePreferenceLi(li)) {
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
      if (seen.has(href)) {
        return;
      }
      seen.add(href);
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
    const rows = [
      {
        id: "account",
        href: getURL(`${base}/account`),
        label: i18n("user.preferences_nav.account"),
        isActive: this.isActiveAccount(),
      },
      {
        id: "security",
        href: getURL(`${base}/security`),
        label: i18n("user.preferences_nav.security"),
        isActive: this.isActiveSegment("security"),
      },
      {
        id: "profile",
        href: getURL(`${base}/profile`),
        label: i18n("user.preferences_nav.profile"),
        isActive: this.isActiveSegment("profile"),
      },
      {
        id: "emails",
        href: getURL(`${base}/emails`),
        label: i18n("user.preferences_nav.emails"),
        isActive: this.isActiveSegment("emails"),
      },
      {
        id: "notifications",
        href: getURL(`${base}/notifications`),
        label: i18n("user.preferences_nav.notifications"),
        isActive: this.isActiveSegment("notifications"),
      },
    ];

    if (this.canChangeTrackingPreferences) {
      rows.push({
        id: "tracking",
        href: getURL(`${base}/tracking`),
        label: i18n("user.preferences_nav.tracking"),
        isActive: this.isActiveSegment("tracking"),
      });
    }

    rows.push(
      {
        id: "users",
        href: getURL(`${base}/users`),
        label: i18n("user.preferences_nav.users"),
        isActive: this.isActiveSegment("users"),
      },
      {
        id: "interface",
        href: getURL(`${base}/interface`),
        label: i18n("user.preferences_nav.interface"),
        isActive: this.isActiveSegment("interface"),
      },
      {
        id: "navigation-menu",
        href: getURL(`${base}/navigation-menu`),
        label: i18n("user.preferences_nav.navigation_menu"),
        isActive: this.isActiveSegment("navigation-menu"),
      }
    );

    return rows;
  }

  get rows() {
    const plugins = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));
    return [...this.coreRows, ...plugins];
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
      const onPreferencesRoute =
        url === "/my/preferences" ||
        url.startsWith("/my/preferences/") ||
        /^\/u\/[^/]+\/preferences(\/|$)/.test(url) ||
        (this.router.currentRouteName || "").startsWith("preferences.");

      if (!onPreferencesRoute) {
        return;
      }

      const nav = document.querySelector(
        "#main-outlet .user-main .user-navigation.user-navigation-secondary"
      );
      const horiz = nav?.querySelector(":scope > nav.horizontal-overflow-nav");
      if (nav && horiz) {
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
      class="fomio-preferences-section-menu__host"
      aria-hidden="true"
    ></span>
    {{#if (and this.insertion)}}
      {{#in-element this.insertion.parent insertBefore=null}}
        <nav
          class="fomio-preferences-section-menu fomio-section-menu--expanded-shell {{if this.hasMirroredPlugins 'fomio-preferences-section-menu--mirrored-plugins'}}"
          aria-label={{this.navAriaLabel}}
        >
          <h2 class="fomio-preferences-section-menu__title">{{this.sectionTitle}}</h2>
          <ul class="fomio-preferences-section-menu__list">
            {{#each this.rows as |row|}}
              <li
                class="fomio-preferences-section-menu__item {{if
                  row.isActive
                  'fomio-section-menu__item--h2-active-card-source'
                }}"
              >
                <a
                  href={{row.href}}
                  class="fomio-preferences-section-menu__link {{if row.isActive 'is-active'}}"
                  aria-current={{if row.isActive "page"}}
                >
                  {{row.label}}
                </a>
              </li>
            {{/each}}
          </ul>
          {{#if this.activeRow}}
            <div
              class="fomio-section-menu__active-card fomio-section-menu__active-card--preferences-soft"
            >
              <a
                href={{this.activeRow.href}}
                class="fomio-section-menu__active-card-link fomio-section-menu__active-card-link--preferences-soft"
                aria-current="page"
              >{{this.activeRow.label}}</a>
            </div>
          {{/if}}
        </nav>
      {{/in-element}}
    {{/if}}
  </template>
}
