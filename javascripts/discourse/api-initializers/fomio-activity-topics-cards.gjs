import { apiInitializer } from "discourse/lib/api";
import { isFomioActivityTopicsPath } from "../lib/fomio-activity-paths";

const TOPIC_LIST_SELECTOR = "#main-outlet .user-main #user-content .topic-list";
const TOPIC_ITEM_SELECTOR = `${TOPIC_LIST_SELECTOR} .topic-list-item`;
const ACTIVITY_TOPICS_LIST_CLASS = "fomio-activity-topics-list";
const ACTIVITY_TOPICS_ITEM_CLASS = "--fomio-activity-topics-card";

function decorateTopicsList() {
  if (typeof document === "undefined") {
    return;
  }

  const currentUrl = window.location.pathname + window.location.search;
  if (!isFomioActivityTopicsPath(currentUrl)) {
    return;
  }

  document.querySelectorAll(TOPIC_LIST_SELECTOR).forEach((list) => {
    list.classList.add(ACTIVITY_TOPICS_LIST_CLASS);
  });

  document.querySelectorAll(TOPIC_ITEM_SELECTOR).forEach((item) => {
    item.classList.add(ACTIVITY_TOPICS_ITEM_CLASS);
  });
}

function scheduleDecoration() {
  if (typeof window === "undefined" || typeof window.requestAnimationFrame !== "function") {
    decorateTopicsList();
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      decorateTopicsList();
    });
  });
}

export default apiInitializer("1.8.0", (api) => {
  let observer;

  const refreshDecoration = () => {
    observer?.disconnect();
    scheduleDecoration();

    const currentUrl = window.location.pathname + window.location.search;
    if (
      !isFomioActivityTopicsPath(currentUrl) ||
      typeof MutationObserver === "undefined"
    ) {
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
