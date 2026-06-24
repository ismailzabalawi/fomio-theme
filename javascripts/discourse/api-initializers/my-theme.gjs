import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { isFomioActivityTopicsPath } from "../lib/fomio-activity-paths";

const PHOSPHOR_ICON_REPLACEMENTS = {
  "angle-right": "fomio-ph-caret-right",
  "bars-staggered": "fomio-ph-rows",
  bell: "fomio-ph-bell",
  bold: "fomio-ph-text-b",
  book: "fomio-ph-book",
  bookmark: "fomio-ph-bookmark",
  certificate: "fomio-ph-certificate",
  "chevron-left": "fomio-ph-caret-left",
  clock: "fomio-ph-clock",
  comment: "fomio-ph-chat-circle",
  compass: "fomio-ph-compass",
  envelope: "fomio-ph-envelope",
  fire: "fomio-ph-fire",
  gear: "fomio-ph-gear",
  heart: "fomio-ph-heart",
  house: "fomio-ph-house",
  italic: "fomio-ph-text-italic",
  link: "fomio-ph-link-simple",
  list: "fomio-ph-list-bullets",
  "magnifying-glass": "fomio-ph-magnifying-glass",
  "pen-to-square": "fomio-ph-plus",
  "sign-out": "fomio-ph-sign-out",
  "table-cells": "fomio-ph-table",
  thumbtack: "fomio-ph-push-pin",
  user: "fomio-ph-user",
  "user-plus": "fomio-ph-user-plus",
  wrench: "fomio-ph-wrench",
  xmark: "fomio-ph-x",
};

const ACTIVITY_TOPICS_LIST_SELECTOR = "#main-outlet .user-main #user-content .topic-list";
const ACTIVITY_TOPICS_ITEM_SELECTOR = `${ACTIVITY_TOPICS_LIST_SELECTOR} .topic-list-item`;

// The activity *stream* (All / Replies / Likes Given) is decorated by
// api-initializers/fomio-activity-stream-list.gjs and styled by the
// editorial activity feed section in common.scss.
function decorateActivitySurfaces() {
  if (typeof document === "undefined" || typeof window === "undefined") {
    return;
  }

  const currentUrl = window.location.pathname + window.location.search;

  if (isFomioActivityTopicsPath(currentUrl)) {
    document.querySelectorAll(ACTIVITY_TOPICS_LIST_SELECTOR).forEach((list) => {
      list.classList.add("fomio-activity-topics-list");
    });

    document.querySelectorAll(ACTIVITY_TOPICS_ITEM_SELECTOR).forEach((item) => {
      item.classList.add("--fomio-activity-topics-card");
    });
  }
}

function scheduleActivityDecoration() {
  if (typeof window === "undefined" || typeof window.requestAnimationFrame !== "function") {
    decorateActivitySurfaces();
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      decorateActivitySurfaces();
    });
  });
}

function isActivityTopicsPage() {
  if (typeof window === "undefined") {
    return false;
  }

  return isFomioActivityTopicsPath(
    window.location.pathname + window.location.search
  );
}

export default apiInitializer("1.8.0", (api) => {
  let activityObserver;

  for (const [source, target] of Object.entries(PHOSPHOR_ICON_REPLACEMENTS)) {
    api.replaceIcon(source, target);
  }

  api.disableDefaultKeyboardShortcuts(["="]);

  api.addPostClassesCallback((post) => {
    if ((post?.post_number ?? 0) > 1) {
      return ["fomio-comment-post"];
    }
  });

  api.registerValueTransformer("post-article-class", ({ value: classes, context }) => {
    if ((context.post?.post_number ?? 0) > 1) {
      classes.push("fomio-comment", "is-reply");
    }

    return classes;
  });

  api.registerValueTransformer("topic-list-class", ({ value: classes, context }) => {
    if (context.listContext === "discovery") {
      classes.push("--fomio-discovery-list");
    }

    if (context.listContext === "suggested") {
      classes.push("--fomio-fresh-bytes-list");
    }

    if (context.listContext === "user-activity" && isActivityTopicsPage()) {
      classes.push("fomio-activity-topics-list");
    }

    return classes;
  });

  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value: classes, context }) => {
      if (context.listContext === "discovery") {
        classes.push("--fomio-discovery-item");
      }

      if (context.listContext === "suggested") {
        classes.push("--fomio-fresh-byte-item");
      }

      if (context.listContext === "user-activity" && isActivityTopicsPage()) {
        classes.push("--fomio-activity-topics-card");
      }

      return classes;
    }
  );

  api.registerValueTransformer("topic-list-columns", ({ value: columns, context }) => {
    if (context.listContext === "user-activity" && isActivityTopicsPage()) {
      columns.delete("views");
      return columns;
    }

    if (!["discovery", "suggested"].includes(context.listContext)) {
      return columns;
    }

    columns.delete("posters");
    columns.delete("views");

    return columns;
  });

  api.registerValueTransformer(
    "welcome-banner-display-for-route",
    ({ value, context }) => {
      if (context.currentRouteName?.startsWith("discovery.")) {
        return false;
      }

      return value;
    }
  );

  api.modifyClass("component:suggested-topics", {
    pluginId: "fomio-fresh-bytes",

    get suggestedTitle() {
      const href = this.currentUser?.pmPath(this.args.topic);
      if (href && this.args.topic.isPrivateMessage) {
        return i18n("suggested_topics.pm_title");
      }

      return i18n(themePrefix("fresh_bytes.title"));
    },
  });

  api.modifyClass("component:more-topics/browse-more", {
    pluginId: "fomio-fresh-bytes",

    get topicBrowseMoreMessage() {
      let unreadTopics = 0;
      let newTopics = 0;

      if (this.currentUser) {
        unreadTopics = this.topicTrackingState.countUnread();
        newTopics = this.topicTrackingState.countNew();
      }

      if (newTopics + unreadTopics > 0) {
        return i18n(themePrefix("fresh_bytes.subtitle"));
      }

      return "";
    },
  });

  const refreshActivityDecoration = () => {
    activityObserver?.disconnect();
    scheduleActivityDecoration();

    if (typeof MutationObserver === "undefined" || typeof document === "undefined") {
      return;
    }

    const currentUrl = window.location.pathname + window.location.search;
    if (!isFomioActivityTopicsPath(currentUrl)) {
      return;
    }

    const userContent = document.querySelector("#main-outlet .user-main #user-content");
    if (!userContent) {
      return;
    }

    activityObserver = new MutationObserver(() => scheduleActivityDecoration());
    activityObserver.observe(userContent, {
      childList: true,
      subtree: true,
    });
  };

  refreshActivityDecoration();
  api.onPageChange(refreshActivityDecoration);
});
