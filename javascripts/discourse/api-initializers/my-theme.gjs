import { apiInitializer } from "discourse/lib/api";
import HomepageShell from "../components/homepage-shell";

export default apiInitializer("1.8.0", (api) => {
  api.disableDefaultKeyboardShortcuts([
    "=",
    "c",
    "shift+c",
    "q",
    "r",
    "shift+r",
    "t",
  ]);

  // Verified: discourse/frontend/discourse/app/templates/application.gjs:106
  // <PluginOutlet @name="above-main-container" @connectorTagName="div" />
  api.renderInOutlet("above-main-container", HomepageShell);

  api.registerValueTransformer("topic-list-class", ({ value: classes, context }) => {
    if (context.listContext === "discovery") {
      classes.push("--fomio-discovery-list");
    }

    return classes;
  });

  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value: classes, context }) => {
      if (context.listContext === "discovery") {
        classes.push("--fomio-discovery-item");
      }

      return classes;
    }
  );

  api.registerValueTransformer("topic-list-columns", ({ value: columns, context }) => {
    if (context.listContext !== "discovery") {
      return columns;
    }

    columns.delete("posters");
    columns.delete("views");

    return columns;
  });

  api.registerValueTransformer("create-topic-button-class", ({ value: classes }) => {
    classes.push("fomio-read-only-hidden");
    return classes;
  });

  api.registerValueTransformer("post-menu-buttons", ({ value: dag }) => {
    dag.delete("reply");
    dag.delete("replies");
    return dag;
  });

  api.registerValueTransformer(
    "composer-service-cannot-submit-post",
    ({ value, context }) => {
      const action = context.model?.action;

      if (action === "createTopic" || action === "reply" || action === "replyToTopic") {
        return true;
      }

      return value;
    }
  );

  api.registerValueTransformer(
    "welcome-banner-display-for-route",
    ({ value, context }) => {
      if (context.currentRouteName?.startsWith("discovery.")) {
        return false;
      }

      return value;
    }
  );
});
