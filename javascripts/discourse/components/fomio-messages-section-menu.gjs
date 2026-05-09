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

/**
 * Fomio second-level nav for Discourse private messages (Phase M2-F).
 * Mirrors core user-inbox and group-inbox pills only; inbox dropdown (groups, tags,
 * custom rows) stays native. Append via `in-element` + flex `order: -1` like M2-B–E.
 */
export default class FomioMessagesSectionMenu extends Component {
  @service router;

  @tracked insertion = null;

  get pathNoQuery() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get userController() {
    return getOwner(this).lookup("controller:user");
  }

  get viewingSelf() {
    return Boolean(this.userController?.viewingSelf);
  }

  get pmLabelsController() {
    const o = getOwner(this);
    const tryLookups = (names) => {
      for (const n of names) {
        const c = o.lookup(n);
        if (c) {
          return c;
        }
      }
      return null;
    };
    if (this.isGroupContext) {
      const groupCtrl = tryLookups([
        "controller:user-private-messages/group",
        "controller:user-private-messages.group",
        "controller:user-private-messages-group",
      ]);
      if (groupCtrl) {
        return groupCtrl;
      }
    }
    return tryLookups([
      "controller:user-private-messages/user",
      "controller:user-private-messages.user",
      "controller:user-private-messages-user",
      "controller:user-private-messages",
    ]);
  }

  get newRowLabel() {
    const t = this.pmLabelsController?.newLinkText;
    if (typeof t === "string" && t.trim()) {
      return t;
    }
    return i18n("user.messages.new");
  }

  get unreadRowLabel() {
    const t = this.pmLabelsController?.unreadLinkText;
    if (typeof t === "string" && t.trim()) {
      return t;
    }
    return i18n("user.messages.unread");
  }

  get groupSlugSegment() {
    const p = this.pathNoQuery;
    const m = /^\/(?:u\/[^/]+|my)\/messages\/group\/([^/]+)/.exec(p);
    return m ? m[1] : null;
  }

  get isGroupContext() {
    return this.groupSlugSegment != null;
  }

  get messagesBasePath() {
    const p = this.pathNoQuery;
    if (this.isGroupContext) {
      const m = /^(\/(?:u\/[^/]+|my)\/messages\/group\/[^/]+)/.exec(p);
      return m ? m[1] : null;
    }
    const m = /^(\/(?:u\/[^/]+|my)\/messages)/.exec(p);
    return m ? m[1] : null;
  }

  get sectionTitle() {
    return i18n("user.private_messages");
  }

  get navAriaLabel() {
    return i18n(themePrefix("messages_submenu.nav_aria"));
  }

  normPath(path) {
    return (path || "").replace(/\/$/, "") || "/";
  }

  isActiveUserSuffix(suffix) {
    const base = this.messagesBasePath;
    if (!base || this.isGroupContext) {
      return false;
    }
    const p = this.normPath(this.pathNoQuery);
    if (suffix === "") {
      return p === this.normPath(base);
    }
    return p === this.normPath(`${base}/${suffix}`);
  }

  isActiveGroupSuffix(suffix) {
    const base = this.messagesBasePath;
    if (!base || !this.isGroupContext) {
      return false;
    }
    const p = this.normPath(this.pathNoQuery);
    if (suffix === "") {
      return p === this.normPath(base);
    }
    return p === this.normPath(`${base}/${suffix}`);
  }

  get rows() {
    const base = this.messagesBasePath;
    if (!base) {
      return [];
    }

    if (this.isGroupContext) {
      const out = [
        {
          id: "group-latest",
          href: getURL(base),
          label: i18n("categories.latest"),
          isActive: this.isActiveGroupSuffix(""),
        },
      ];
      if (this.viewingSelf) {
        out.push(
          {
            id: "group-new",
            href: getURL(`${base}/new`),
            label: this.newRowLabel,
            isActive: this.isActiveGroupSuffix("new"),
          },
          {
            id: "group-unread",
            href: getURL(`${base}/unread`),
            label: this.unreadRowLabel,
            isActive: this.isActiveGroupSuffix("unread"),
          },
          {
            id: "group-archive",
            href: getURL(`${base}/archive`),
            label: i18n("user.messages.archive"),
            isActive: this.isActiveGroupSuffix("archive"),
          }
        );
      }
      return out;
    }

    const out = [
      {
        id: "latest",
        href: getURL(base),
        label: i18n("categories.latest"),
        isActive: this.isActiveUserSuffix(""),
      },
      {
        id: "sent",
        href: getURL(`${base}/sent`),
        label: i18n("user.messages.sent"),
        isActive: this.isActiveUserSuffix("sent"),
      },
    ];

    if (this.viewingSelf) {
      out.push(
        {
          id: "new",
          href: getURL(`${base}/new`),
          label: this.newRowLabel,
          isActive: this.isActiveUserSuffix("new"),
        },
        {
          id: "unread",
          href: getURL(`${base}/unread`),
          label: this.unreadRowLabel,
          isActive: this.isActiveUserSuffix("unread"),
        }
      );
    }

    out.push({
      id: "archive",
      href: getURL(`${base}/archive`),
      label: i18n("user.messages.archive"),
      isActive: this.isActiveUserSuffix("archive"),
    });

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
      const url = (this.router.currentURL || "").split("?")[0];
      const onMessagesRoute =
        /^\/u\/[^/]+\/messages(\/|$)/.test(url) ||
        /^\/my\/messages(\/|$)/.test(url) ||
        (this.router.currentRouteName || "").startsWith("userPrivateMessages");

      if (!onMessagesRoute) {
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
      class="fomio-messages-section-menu__host"
      aria-hidden="true"
    ></span>
    {{#if (and this.insertion this.messagesBasePath)}}
      {{#in-element this.insertion.parent insertBefore=null}}
        <nav
          class="fomio-messages-section-menu fomio-section-menu--expanded-shell"
          aria-label={{this.navAriaLabel}}
        >
          <h2 class="fomio-messages-section-menu__title">{{this.sectionTitle}}</h2>
          <ul class="fomio-messages-section-menu__list">
            {{#each this.rows as |row|}}
              <li
                class="fomio-messages-section-menu__item {{if
                  row.isActive
                  'fomio-section-menu__item--h2-active-card-source'
                }}"
              >
                <a
                  href={{row.href}}
                  class="fomio-messages-section-menu__link {{if row.isActive 'is-active'}}"
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
