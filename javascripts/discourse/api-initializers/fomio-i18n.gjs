import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer("1.8.0", (api) => {
  api.registerHelper("fomio-t", (key, options) => i18n(`fomio.${key}`, options));
});
