import { apiInitializer } from "discourse/lib/api";

// Home's welcome panel is for visitors. Let core supply its translated
// heading, description and search, and preserve visibility on other routes.
export default apiInitializer((api) => {
  api.registerValueTransformer(
    "welcome-banner-display-for-route",
    ({ value, context }) => {
      if (
        ["discovery.latest", "discovery.hot", context.homepage].includes(
          context.currentRouteName
        )
      ) {
        return !api.getCurrentUser();
      }
      return value;
    }
  );
});
