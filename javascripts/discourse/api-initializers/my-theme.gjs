import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default apiInitializer("1.8.0", (api) => {
  api.disableDefaultKeyboardShortcuts(["="]);

  api.registerValueTransformer("topic-list-class", ({ value: classes, context }) => {
    if (context.listContext === "discovery") {
      classes.push("--fomio-discovery-list");
    }

    if (context.listContext === "suggested") {
      classes.push("--fomio-fresh-bytes-list");
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

      return classes;
    }
  );

  api.registerValueTransformer("topic-list-columns", ({ value: columns, context }) => {
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
});
