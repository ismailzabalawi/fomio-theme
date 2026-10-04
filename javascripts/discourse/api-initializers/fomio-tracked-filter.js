// Tracked filter in the nav row (Phase 2C; docs/05 Q1, docs/08).
//
// `?f=tracked` narrows any topic list to categories the member tracks or
// watches (lib/topic-list-tracked-filter.js, TopicQuery#tracked_filter). Core
// has the feed but no link to it, so this adds one through core's own nav
// API rather than markup. It is an on/off filter over the current tab, not a
// tab: its href adds `f=tracked` to the current list, or removes it when the
// filter is on. Core's top_menu pills keep the param while it is on
// (components/navigation-item.gjs); extra items aren't given the route's
// query params (models/nav-item.js), so this one can switch it off.
//
// The label is core's `user.tracked_categories` — the preferences heading for
// the same set of categories — so its wording stays under Discourse's
// text customization.
import { registerDestructor } from "@ember/destroyable";
import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { hasTrackedFilter } from "discourse/lib/topic-list-tracked-filter";
import { i18n } from "discourse-i18n";

const NAME = "fomio-tracked";
const ON_LINK = `li.${NAME}.--on > a`;
// Core's empty-list state (components/empty-topic-filter.gjs, rendered by
// components/discovery/topics.gjs when a member's list is empty).
const EMPTY_CTA =
  ".empty-state__container.--empty-topic-filter .empty-state__cta .btn";

function isOn(router) {
  return hasTrackedFilter(router.currentRoute?.queryParams);
}

export default apiInitializer((api) => {
  const label = i18n("user.tracked_categories");
  const router = api.container.lookup("service:router");

  // Turning the filter off. `f` is a sticky Ember query param on the list
  // controllers (controllers/discovery/list.js); following the off link's
  // plain URL left members on `?f=tracked` in the preview (2026-09-26). So
  // the click resets the param explicitly with a query-param-only
  // transition on whatever list is showing. The legacy `filter=tracked` is the parent
  // discovery route's param (routes/discovery.js). Capture phase, and
  // preventDefault only: core's click interceptor then skips the link
  // (lib/intercept-click.js, wantsNewWindow), and the mobile nav dropdown
  // still closes. Modified clicks keep the href.
  //
  // The empty state (2D) needs the same reset. With the filter on and nothing
  // tracked, core's "browse latest" button routes to `discovery.latest`, which
  // keeps the sticky `f` — the member lands on the same empty list. So while
  // the filter is on, that button (matched by core's own label,
  // `topic.browse_latest_topics`) opens Latest unfiltered. Core's other
  // empty-state buttons switch the New list's subset and are left alone.
  const browseLatest = i18n("topic.browse_latest_topics");

  const handleTrackedClick = (event) => {
    const link = event.target.closest?.(ON_LINK);
    if (link) {
      if (wantsNewWindow(event, link)) {
        return;
      }
      event.preventDefault();
      router.transitionTo({ queryParams: { f: null, filter: null } });
      return;
    }

    const cta = event.target.closest?.(EMPTY_CTA);
    if (cta && isOn(router) && cta.textContent.trim() === browseLatest) {
      event.preventDefault();
      event.stopPropagation(); // core's button would keep `f`
      router.transitionTo("discovery.latest", {
        queryParams: { f: null, filter: null },
      });
    }
  };
  document.addEventListener("click", handleTrackedClick, true);
  registerDestructor(router, () => {
    document.removeEventListener("click", handleTrackedClick, true);
  });

  api.addNavigationBarItem({
    name: NAME,
    displayName: label,
    title: label,
    before: "categories",

    // Signed-in only: tracking is per member. Not on the categories page,
    // which isn't a topic list.
    customFilter: (category, args) =>
      !!api.getCurrentUser() && args?.filterType !== "categories",

    // The current list with `f=tracked` toggled; other params (order, …)
    // are kept. The off href serves new tabs and no-JS; clicks go through
    // the listener above.
    customHref: (category, args, router) => {
      const url = new URL(router.currentURL ?? "/", window.location.origin);
      if (isOn(router)) {
        url.searchParams.delete("f");
        if (url.searchParams.get("filter") === "tracked") {
          url.searchParams.delete("filter");
        }
      } else {
        url.searchParams.set("f", "tracked");
      }
      return getURL(url.pathname + url.search);
    },

    // A class, not forceActive: forceActive clears every other pill's active
    // state, and Tracked sits on top of the current tab (Latest, Hot, …).
    init: (navItem, category, args, router) => {
      navItem.classNames = isOn(router) ? "--on" : "";
    },
  });
});
