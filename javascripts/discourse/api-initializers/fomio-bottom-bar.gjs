// Mobile navigation (Phase 2A, decided 2026-09-26 — docs/05, Q2).
//
// `navigation_menu: header dropdown` only applies on desktop; below `sm` core
// always keeps its hamburger drawer (services/navigation-menu.js). This bar
// replaces that drawer and the header avatar on mobile, so there is one
// navigation system. Everything it links to is native: /latest, the
// categories page, the composer, core's user menu and the user's profile.
//
// The dock layout is the archived theme's: five items, a filled New Topic
// control, and it slides away while scrolling down. Labels, routes, the
// composer, the user menu, the avatar, and the unread count are Discourse's.
// The archived custom menu, login intent, and product words are not.
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import hideApplicationHeaderButtons from "discourse/helpers/hide-application-header-buttons";
import htmlClass from "discourse/helpers/html-class";
import Composer from "discourse/models/composer";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { nextBottomBarHidden } from "../lib/fomio-bottom-bar-scroll";

// Routes where the bar would get in the way: auth flows (core's FooterNav
// excludes the same list, components/footer-nav.gjs) and admin.
const EXCLUDED_ROUTES = [
  "activate-account",
  "invites.show",
  "login",
  "password-reset",
  "signup",
];

class Bar extends Component {
  @service router;
  @service currentUser;
  @service composer;
  @service header;
  @service appEvents;
  @service siteSettings;

  @tracked scrollHidden = false;
  #lastScrollY = 0;
  #onScroll = null;

  constructor(owner, args) {
    super(owner, args);
    this.#lastScrollY = window.scrollY;
    this.#onScroll = () => {
      const y = window.scrollY;
      const scrollableHeight =
        document.documentElement.scrollHeight - window.innerHeight;
      const hidden = nextBottomBarHidden({
        y,
        previousY: this.#lastScrollY,
        hidden: this.scrollHidden,
        scrollableHeight,
        allowHide: this.allowHide,
      });
      this.#lastScrollY = y;
      if (hidden !== this.scrollHidden && !this.isDestroying) {
        this.scrollHidden = hidden;
      }
    };
    window.addEventListener("scroll", this.#onScroll, { passive: true });
  }

  willDestroy() {
    super.willDestroy();
    window.removeEventListener("scroll", this.#onScroll);
  }

  get routeName() {
    return this.router.currentRouteName ?? "";
  }

  // `composer.isOpen` reads `model.composeState` natively, and the composer
  // model is a classic object whose state core changes with `set`
  // (services/composer.js), so the bar never re-rendered when it opened.
  // Ember's `get` consumes that property's tag.
  get isComposerOpen() {
    return get(this.composer, "model.composeState") === Composer.OPEN;
  }

  get isVisible() {
    return (
      !this.isComposerOpen &&
      !this.routeName.startsWith("admin") &&
      !EXCLUDED_ROUTES.includes(this.routeName)
    );
  }

  get loginUrl() {
    return getURL("/login");
  }

  get prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }

  // The archived bar stayed put on your own profile. It also stays while
  // Discourse's user menu is open, and when the reader asked for less motion.
  get allowHide() {
    return (
      !this.prefersReducedMotion &&
      !this.isProfileActive &&
      !this.header.userVisible
    );
  }

  get isDockHidden() {
    return this.allowHide && this.scrollHidden;
  }

  // Category-scoped lists and the categories page: discovery.categories,
  // .category, .categoryAll, .categoryNone, .subcategories and every
  // <filter>Category route (routes/app-route-map.js).
  get isCategoryRoute() {
    return /ategor/.test(this.routeName);
  }

  // Home goes to /latest (docs/05, Q2). It stays lit on the other site-wide
  // lists — /, /hot, /new (with Unified New's Topics/Replies subsets), /top —
  // because those are the same list under another top_menu tab, reached from
  // Home's own nav pills. A legacy /unread URL still routes and matches too.
  get isHomeActive() {
    return this.routeName.startsWith("discovery.") && !this.isCategoryRoute;
  }

  get isHomeCurrent() {
    return this.routeName === "discovery.latest";
  }

  get isCategoriesCurrent() {
    return this.routeName === "discovery.categories";
  }

  get isCategoriesActive() {
    return this.routeName.startsWith("discovery.") && this.isCategoryRoute;
  }

  get profileUrl() {
    return getURL(`/u/${this.currentUser.username_lower}`);
  }

  get isProfileActive() {
    const path = `/u/${this.currentUser?.username_lower}`;
    const url = this.router.currentURL ?? "";
    return url === path || url.startsWith(`${path}/`);
  }

  get unreadCount() {
    return this.currentUser?.all_unread_notifications_count;
  }

  get messagesCount() {
    return this.currentUser?.unread_private_messages;
  }

  // Opened from a category page, the composer starts in that category, as
  // core's own New Topic button does there (controllers/discovery/list.js,
  // createTopicTargetCategory): the category if the member can post in it,
  // else a subcategory they can post in when
  // default_subcategory_on_read_only_category is on, else the category
  // (core's openNewTopic then marks it read-only). Elsewhere core's default
  // composer category applies, as before (3E, 2026-09-27).
  get newTopicCategory() {
    const category = this.router.currentRoute?.attributes?.category;
    if (!category || category.canCreateTopic) {
      return category;
    }
    return (
      (this.siteSettings.default_subcategory_on_read_only_category &&
        category.subcategoryWithCreateTopicPermission) ||
      category
    );
  }

  @action
  newTopic() {
    this.composer.openNewTopic({ category: this.newTopicCategory });
  }

  // Opens core's own user menu, the panel the header avatar opens.
  @action
  toggleUserMenu() {
    this.appEvents.trigger("header:keyboard-trigger", { type: "user" });
  }

  <template>
    {{#if this.isVisible}}
      {{! The bar replaces core's drawer, so the drawer's toggle goes while
        the bar shows — core's own helper, undone when the bar hides. Where
        the bar hides (admin, auth), the hamburger comes back. }}
      {{hideApplicationHeaderButtons "menu"}}

      {{! footer-nav-visible is core's class for a visible footer nav: it pads
        #main-outlet and lifts the topic progress bar, nested-view actions and
        the iOS composer above it (common/components/footer-nav.scss).
        fomio-bottom-bar hides the header avatar the bar replaces. }}
      {{htmlClass "footer-nav-visible fomio-bottom-bar-visible"}}

      <nav
        class={{dConcatClass
          "fomio-bottom-bar"
          (if this.isDockHidden "fomio-bottom-bar--hidden")
        }}
        aria-label={{i18n "hamburger_menu"}}
        aria-hidden={{if this.isDockHidden "true"}}
      >
        <a
          href={{getURL "/latest"}}
          class={{dConcatClass
            "fomio-bottom-bar__item"
            (if this.isHomeActive "active")
          }}
          aria-current={{if this.isHomeCurrent "page"}}
          tabindex={{if this.isDockHidden "-1"}}
        >
          {{dIcon "house"}}
          <span class="fomio-bottom-bar__label">{{i18n "home"}}</span>
        </a>

        <a
          href={{getURL "/categories"}}
          class={{dConcatClass
            "fomio-bottom-bar__item"
            (if this.isCategoriesActive "active")
          }}
          aria-current={{if this.isCategoriesCurrent "page"}}
          tabindex={{if this.isDockHidden "-1"}}
        >
          {{dIcon "list"}}
          <span class="fomio-bottom-bar__label">
            {{i18n "filters.categories.title"}}
          </span>
        </a>

        {{#if this.currentUser}}
          {{#if this.currentUser.can_create_topic}}
            <button
              type="button"
              class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
              tabindex={{if this.isDockHidden "-1"}}
              {{on "click" this.newTopic}}
            >
              <span class="fomio-bottom-bar__icon">{{dIcon "plus"}}</span>
              <span class="fomio-bottom-bar__label">
                {{i18n "topic.create"}}
              </span>
            </button>
          {{else}}
            <button
              type="button"
              class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
              disabled
              tabindex={{if this.isDockHidden "-1"}}
            >
              <span class="fomio-bottom-bar__icon">{{dIcon "plus"}}</span>
              <span class="fomio-bottom-bar__label">
                {{i18n "topic.create"}}
              </span>
            </button>
          {{/if}}
        {{else}}
          <a
            href={{this.loginUrl}}
            class="fomio-bottom-bar__item fomio-bottom-bar__item--create"
            tabindex={{if this.isDockHidden "-1"}}
          >
            <span class="fomio-bottom-bar__icon">{{dIcon "plus"}}</span>
            <span class="fomio-bottom-bar__label">
              {{i18n "topic.create"}}
            </span>
          </a>
        {{/if}}

        {{#if this.currentUser}}
          <button
            type="button"
            class={{dConcatClass
              "fomio-bottom-bar__item"
              (if this.header.userVisible "active")
            }}
            aria-haspopup="true"
            aria-expanded={{if this.header.userVisible "true" "false"}}
            tabindex={{if this.isDockHidden "-1"}}
            {{on "click" this.toggleUserMenu}}
          >
            <span class="fomio-bottom-bar__icon">
              {{! Regular while closed, solid while the menu is open. }}
              {{dIcon (if this.header.userVisible "bell" "far-bell")}}
              {{#if this.unreadCount}}
                <span class="badge-notification unread-notifications">
                  {{this.unreadCount}}
                </span>
              {{/if}}
            </span>
            <span class="fomio-bottom-bar__label">
              {{i18n "user.notifications"}}
            </span>
          </button>

          <a
            href={{this.profileUrl}}
            class={{dConcatClass
              "fomio-bottom-bar__item"
              (if this.isProfileActive "active")
            }}
            aria-current={{if this.isProfileActive "page"}}
            tabindex={{if this.isDockHidden "-1"}}
          >
            <span class="fomio-bottom-bar__icon">
              {{dAvatar this.currentUser imageSize="small" ignoreTitle=true}}
              {{#if this.messagesCount}}
                <span class="badge-notification unread-notifications">
                  {{this.messagesCount}}
                </span>
              {{/if}}
            </span>
            <span class="fomio-bottom-bar__label">{{i18n "user.profile"}}</span>
          </a>
        {{else}}
          <a
            href={{this.loginUrl}}
            class="fomio-bottom-bar__item"
            tabindex={{if this.isDockHidden "-1"}}
          >
            <span class="fomio-bottom-bar__icon">{{dIcon "far-bell"}}</span>
            <span class="fomio-bottom-bar__label">
              {{i18n "user.notifications"}}
            </span>
          </a>

          <a
            href={{this.loginUrl}}
            class="fomio-bottom-bar__item"
            tabindex={{if this.isDockHidden "-1"}}
          >
            {{dIcon "user"}}
            <span class="fomio-bottom-bar__label">{{i18n "user.profile"}}</span>
          </a>
        {{/if}}
      </nav>
    {{/if}}
  </template>
}

class FomioBottomBar extends Component {
  @service site;

  // `site.mobileView` follows the viewport (below `sm`, models/site.js), so
  // the bar — and the hamburger hider inside it — come and go on resize.
  <template>
    {{#if this.site.mobileView}}
      <Bar />
    {{/if}}
  </template>
}

export default apiInitializer((api) => {
  api.renderInOutlet("below-footer", FomioBottomBar);
});
