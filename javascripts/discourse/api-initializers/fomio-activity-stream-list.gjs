import { apiInitializer } from "discourse/lib/api";

const ACTIVITY_STREAM_PATH =
  /^\/(?:u\/[^/]+|my)\/activity(?:\/(?:replies|likes-given))?(?:\/.*)?(?:\?.*)?$/i;
const STREAM_SELECTOR = "#main-outlet .user-main #user-content .user-stream";
const STREAM_ITEM_SELECTOR = `${STREAM_SELECTOR} .item, ${STREAM_SELECTOR} .user-stream-item, ${STREAM_SELECTOR} .stream-item`;
const ACTIVITY_STREAM_LIST_CLASS = "fomio-activity-stream-list fomio-list";
const ACTIVITY_STREAM_ITEM_CLASS = "fomio-list__item fomio-list__item--activity";

function isActivityStreamPath(url = "") {
  const path = url.split("#")[0];
  return ACTIVITY_STREAM_PATH.test(path);
}

function decorateActivityStream() {
  if (typeof document === "undefined") {
    return;
  }

  const currentUrl = window.location.pathname + window.location.search;
  if (!isActivityStreamPath(currentUrl)) {
    return;
  }

  document.querySelectorAll(STREAM_SELECTOR).forEach((stream) => {
    stream.classList.add(...ACTIVITY_STREAM_LIST_CLASS.split(" "));
  });

  document.querySelectorAll(STREAM_ITEM_SELECTOR).forEach((item) => {
    item.classList.add(...ACTIVITY_STREAM_ITEM_CLASS.split(" "));
  });
}

function scheduleDecoration() {
  if (typeof window === "undefined" || typeof window.requestAnimationFrame !== "function") {
    decorateActivityStream();
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      decorateActivityStream();
    });
  });
}

export default apiInitializer("1.8.0", (api) => {
  let observer;

  const refreshDecoration = () => {
    observer?.disconnect();
    scheduleDecoration();

    const currentUrl = window.location.pathname + window.location.search;
    if (!isActivityStreamPath(currentUrl) || typeof MutationObserver === "undefined") {
      return;
    }

    const userContent = document.querySelector("#main-outlet .user-main #user-content");
    if (!userContent) {
      return;
    }

    observer = new MutationObserver(() => scheduleDecoration());
    observer.observe(userContent, {
      childList: true,
      subtree: true,
    });
  };

  refreshDecoration();
  api.onPageChange(refreshDecoration);
});
