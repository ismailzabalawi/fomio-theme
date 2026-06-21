import { apiInitializer } from "discourse/lib/api";
import {
  getMessagesState,
  setMessagesState,
  resetMessagesState,
} from "../lib/fomio-messages-state";
import { parseFomioMessagesPath } from "../lib/fomio-messages-routes";

export default apiInitializer("1.8.0", (api) => {
  api.onPageChange((url) => {
    const routeState = parseFomioMessagesPath(url);

    if (routeState.isMessagesPath) {
      const currentState = getMessagesState();
      const routeChanged =
        currentState.filter !== routeState.filter ||
        currentState.activeGroupName !== routeState.groupName ||
        currentState.activeGroupFilter !== (routeState.groupFilter || "inbox");

      setMessagesState({
        filter: routeState.filter,
        activeGroupName: routeState.groupName,
        activeGroupFilter: routeState.groupFilter || "inbox",
        selectedTopicId: routeChanged ? null : currentState.selectedTopicId,
      });
    }
  });

  api.onAppEvent("user:logged-out", () => {
    resetMessagesState();
  });
});
