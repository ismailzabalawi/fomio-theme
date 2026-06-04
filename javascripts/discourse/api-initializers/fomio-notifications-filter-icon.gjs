import { apiInitializer } from "discourse/lib/api";
import { scheduleNotificationsFilterIconDecoration } from "../lib/fomio-notifications-filter-icon";

export default apiInitializer("1.8.0", (api) => {
  scheduleNotificationsFilterIconDecoration();
  api.onPageChange(() => scheduleNotificationsFilterIconDecoration());
});
