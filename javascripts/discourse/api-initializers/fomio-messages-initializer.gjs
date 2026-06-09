import { apiInitializer } from "discourse/lib/api";
import {
  setMessagesState,
  resetMessagesState,
} from "../lib/fomio-messages-state";
import { parseFomioMessagesPath } from "../lib/fomio-messages-routes";

export default apiInitializer("1.8.0", (api) => {
  api.onPageChange((url) => {
    const routeState = parseFomioMessagesPath(url);

    if (routeState.isMessagesPath) {
      setMessagesState({
        filter: routeState.filter,
        activeGroupName: routeState.groupName,
        activeGroupFilter: routeState.groupFilter || "inbox",
      });
    }
  });

  api.onAppEvent("user:logged-out", () => {
    resetMessagesState();
  });
});
