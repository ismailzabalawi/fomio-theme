// Mobile list tabs (Phase 2E; roadmap: "mobile only changes density —
// compact, horizontal tabs"). Decided with the user 2026-09-26.
//
// Below `sm` core folds the list's nav pills into a dropdown whose trigger
// shows only the current tab (components/navigation-bar.gjs, showDropdown),
// so on a phone the Tracked filter's on-state was invisible. Core's own
// `navigation-bar-dropdown-mode` value transformer (default
// `site.mobileView`) keeps the same pills inline instead; common.scss gives
// them a row that scrolls sideways. No markup, no strings.
import { schedule } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";

// Scrolls the tab row — never the page — so the active tab is in view.
// At 375px the five top_menu tabs plus Tracked are wider than the column,
// and Categories or Tracked can start off-screen.
function revealActiveTab() {
  const bar = document.querySelector(".list-controls #navigation-bar");
  const active = bar?.querySelector(
    ":scope > li > a.active, :scope > li.--on > a"
  );
  if (!active || bar.scrollWidth <= bar.clientWidth) {
    return;
  }

  const start =
    active.getBoundingClientRect().left -
    bar.getBoundingClientRect().left +
    bar.scrollLeft;
  const end = start + active.offsetWidth;
  if (start < bar.scrollLeft || end > bar.scrollLeft + bar.clientWidth) {
    bar.scrollLeft = start - (bar.clientWidth - active.offsetWidth) / 2;
  }
}

export default apiInitializer((api) => {
  api.registerValueTransformer("navigation-bar-dropdown-mode", () => false);

  // Route and query-param changes (Tracked on/off) both re-render the row.
  const router = api.container.lookup("service:router");
  router.on("routeDidChange", () =>
    schedule("afterRender", revealActiveTab)
  );
});
