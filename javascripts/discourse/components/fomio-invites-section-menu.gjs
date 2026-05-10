import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
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
 * Fomio second-level nav for Discourse user invites (Phase M2-E).
 * Phase H4-C: when the user-shell plugin decorates the wrapper and the surface is
 * touch, inactive status rows render after native `[data-fomio-user-content]` so the
 * active filter reads as an opened card with leaf content inside, then other filters.
 */
export default class FomioInvitesSectionMenu extends Component {
  @service router;
  @service site;
  @service siteSettings;

  @tracked insertion = null;
  @tracked insertionAfterContent = null;
  @tracked invitesLayoutVariant = "legacy";

  _onRouteDidChange = () => {
    this.insertion = null;
    this.insertionAfterContent = null;
    this.invitesLayoutVariant = "legacy";
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

  get invitedController() {
    return getOwner(this).lookup("controller:user-invited");
  }

  get username() {
    const m = /^\/u\/([^/]+)\/invited/.exec(this.pathNoQuery);
    return m ? decodeURIComponent(m[1]) : null;
  }

  get basePath() {
    const u = this.username;
    return u ? `/u/${u}/invited` : null;
  }

  get sectionTitle() {
    return i18n("user.invited.title");
  }

  get navAriaLabel() {
    return i18n(themePrefix("invites_submenu.nav_aria"));
  }

  get inactiveTailAriaLabel() {
    return i18n(themePrefix("invites_submenu.inactive_aria"));
  }

  isActiveForFilter(filterId) {
    const base = this.basePath;
    if (!base) {
      return false;
    }
    if (filterId === "pending") {
      return (
        fomioPathsEqual(this.pathNoQuery, base) ||
        fomioPathsEqual(this.pathNoQuery, `${base}/pending`)
      );
    }
    return fomioPathsEqual(this.pathNoQuery, `${base}/${filterId}`);
  }

  get rows() {
    const base = this.basePath;
    if (!base) {
      return [];
    }

    const ctrl = this.invitedController;
    const pendingLabel = ctrl?.pendingLabel ?? i18n("user.invited.pending_tab");
    const expiredLabel = ctrl?.expiredLabel ?? i18n("user.invited.expired_tab");
    const redeemedLabel = ctrl?.redeemedLabel ?? i18n("user.invited.redeemed_tab");

    return [
      {
        id: "pending",
        href: getURL(`${base}/pending`),
        label: pendingLabel,
        isActive: this.isActiveForFilter("pending"),
      },
      {
        id: "expired",
        href: getURL(`${base}/expired`),
        label: expiredLabel,
        isActive: this.isActiveForFilter("expired"),
      },
      {
        id: "redeemed",
        href: getURL(`${base}/redeemed`),
        label: redeemedLabel,
        isActive: this.isActiveForFilter("redeemed"),
      },
    ];
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
      const onInvitedRoute =
        /^\/u\/[^/]+\/invited(\/|$)/.test(url) ||
        (this.router.currentRouteName || "").startsWith("userInvited");

      if (!onInvitedRoute) {
        if (this.insertion || this.insertionAfterContent) {
          this.insertion = null;
          this.insertionAfterContent = null;
          this.invitesLayoutVariant = "legacy";
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
        wrapper?.dataset?.fomioUserSection === "invites";

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
        this.invitesLayoutVariant = useOption3 ? "option3" : "legacy";
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
      class="fomio-invites-section-menu__host"
      aria-hidden="true"
    ></span>
    {{#if (and this.insertion this.username)}}
      {{#in-element this.insertion.parent insertBefore=null}}
        {{#if (eq this.invitesLayoutVariant "option3")}}
          <nav
            class="fomio-invites-section-menu fomio-invites-section-menu--option3-head fomio-section-menu--expanded-shell"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-invites-section-menu__title">{{this.sectionTitle}}</h2>
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
            class="fomio-invites-section-menu fomio-section-menu--expanded-shell"
            aria-label={{this.navAriaLabel}}
          >
            <h2 class="fomio-invites-section-menu__title">{{this.sectionTitle}}</h2>
            <ul class="fomio-invites-section-menu__list">
              {{#each this.rows as |row|}}
                <li
                  class="fomio-invites-section-menu__item {{if
                    row.isActive
                    'fomio-section-menu__item--h2-active-card-source'
                  }}"
                >
                  <a
                    href={{row.href}}
                    class="fomio-invites-section-menu__link {{if row.isActive 'is-active'}}"
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
        (eq this.invitesLayoutVariant "option3")
        this.insertionAfterContent
        (gt this.inactiveRows.length 0)
      )
    }}
      {{#in-element this.insertionAfterContent.parent insertBefore=null}}
        <ul
          class="fomio-invites-section-menu__list fomio-invites-section-menu__inactive-tail"
          aria-label={{this.inactiveTailAriaLabel}}
        >
          {{#each this.inactiveRows as |row|}}
            <li class="fomio-invites-section-menu__item">
              <a
                href={{row.href}}
                class="fomio-invites-section-menu__link"
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
