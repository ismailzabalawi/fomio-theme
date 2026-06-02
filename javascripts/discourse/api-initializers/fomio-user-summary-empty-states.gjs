import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

const EMPTY_SUMMARY_SELECTORS = [
  {
    selector: ".replies-section ul",
    message: "user.summary.no_replies",
  },
  {
    selector: ".topics-section ul",
    message: "user.summary.no_topics",
  },
  {
    selector: ".replied-section ul",
    message: "user.summary.no_replies",
  },
  {
    selector: ".liked-by-section ul",
    message: "user.summary.no_likes",
  },
  {
    selector: ".liked-section ul",
    message: "user.summary.no_likes",
  },
  {
    selector: ".badges-section .badge-group-list",
    message: "user.summary.no_badges",
  },
];

function syncSummaryEmptyStates() {
  if (typeof document === "undefined" || !document.body) {
    return;
  }

  if (!document.body.classList.contains("user-summary-page")) {
    return;
  }

  const userContent = document.querySelector("#user-content");
  if (!userContent) {
    return;
  }

  for (const { selector, message } of EMPTY_SUMMARY_SELECTORS) {
    const node = userContent.querySelector(selector);
    if (!node) {
      continue;
    }

    const isEmpty = node.children.length === 0;
    node.classList.toggle("fomio-summary-empty", isEmpty);

    if (isEmpty) {
      node.setAttribute("data-fomio-empty-message", i18n(message));
    } else {
      node.removeAttribute("data-fomio-empty-message");
    }
  }
}

function scheduleSummaryEmptyStateSync() {
  if (typeof window === "undefined" || typeof window.requestAnimationFrame !== "function") {
    syncSummaryEmptyStates();
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      syncSummaryEmptyStates();
    });
  });
}

export default apiInitializer("1.8.0", (api) => {
  scheduleSummaryEmptyStateSync();
  api.onPageChange(() => scheduleSummaryEmptyStateSync());
});
