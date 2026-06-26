import { apiInitializer } from "discourse/lib/api";
import { isFomioActivityBytesPath } from "../lib/fomio-activity-paths";

const TOPIC_LIST_SELECTOR = "#main-outlet .user-main #user-content .topic-list";
const ACTIVITY_TOPICS_LIST_CLASS = "fomio-activity-topics-list";

function decorateTopicsList() {
  if (typeof document === "undefined") {
    return;
  }

  const currentUrl = window.location.pathname + window.location.search;
  if (!isFomioActivityBytesPath(currentUrl)) {
    return;
  }

  document.querySelectorAll(TOPIC_LIST_SELECTOR).forEach((list) => {
    list.classList.add(ACTIVITY_TOPICS_LIST_CLASS);
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
      !isFomioActivityBytesPath(currentUrl) ||
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
