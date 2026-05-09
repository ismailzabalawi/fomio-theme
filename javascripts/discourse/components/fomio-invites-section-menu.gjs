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

/**
 * Fomio second-level nav for Discourse user invites (Phase M2-E).
 * Same insertion pattern as M2-B/C/D: append via `in-element` + flex `order: -1`.
 * Mount only when native `.user-navigation-secondary` exists (gated by Discourse
 * `can_see_invite_details` in `user-invited.gjs`).
 */
export default class FomioInvitesSectionMenu extends Component {
  @service router;

  @tracked insertion = null;

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
      const onInvitedRoute =
        /^\/u\/[^/]+\/invited(\/|$)/.test(url) ||
        (this.router.currentRouteName || "").startsWith("userInvited");

      if (!onInvitedRoute) {
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
      class="fomio-invites-section-menu__host"
      aria-hidden="true"
    ></span>
    {{#if (and this.insertion this.username)}}
      {{#in-element this.insertion.parent insertBefore=null}}
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
      {{/in-element}}
    {{/if}}
  </template>
}
