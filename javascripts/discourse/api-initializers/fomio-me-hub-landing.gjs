import { next } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";
import { syncMeHubLandingBodyClass } from "../lib/fomio-me-hub-landing";

export default apiInitializer("1.8.0", (api) => {
  function sync() {
    const router = api.container.lookup("service:router");
    const url = router?.currentURL || "";
    const user = api.getCurrentUser();
    next(() => syncMeHubLandingBodyClass(url, user));
  }

  sync();
  api.onPageChange(() => sync());
});
