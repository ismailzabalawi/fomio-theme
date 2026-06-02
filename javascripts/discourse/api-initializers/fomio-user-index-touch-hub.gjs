import { apiInitializer } from "discourse/lib/api";
import { shouldUseOwnProfileRootAsMeHub } from "../lib/fomio-mobile-nav-paths";

export default apiInitializer("1.8.0", (api) => {
  api.modifyClass("route:user.index", {
    pluginId: "fomio-user-index-touch-hub",

    beforeModel() {
      const currentUser = this.currentUser;
      const viewedUsername = this.modelFor("user")?.username;
      const isTouchShell = Boolean(
        typeof document !== "undefined" &&
          document.body?.classList.contains("fomio-surface-touch")
      );

      if (
        shouldUseOwnProfileRootAsMeHub(currentUser, viewedUsername, {
          isTouchShell,
        })
      ) {
        return;
      }

      const viewingMe =
        currentUser?.username?.toLowerCase() ===
        viewedUsername?.toLowerCase();

      const destination = viewingMe
        ? "userActivity"
        : this.viewingOtherUserDefaultRoute;

      this.router.transitionTo(destination);
    },
  });
});
