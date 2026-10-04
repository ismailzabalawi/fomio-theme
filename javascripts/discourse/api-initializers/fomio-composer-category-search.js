import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  // The pinned native filter renders its own Input but exposes no aria-label
  // argument. Preserve that input and all its native handlers. Only name the
  // category filter inside the composer; other SelectKit filters are untouched.
  api.modifyClass("component:select-kit/select-kit-filter", {
    pluginId: "fomio-composer-category-search",

    didRender() {
      this._super(...arguments);

      if (!this.element?.closest("#reply-control .category-chooser")) {
        return;
      }

      const input = this.element.querySelector("input.filter-input");
      if (input && !input.hasAttribute("aria-labelledby")) {
        input.setAttribute(
          "aria-label",
          i18n(themePrefix("composer.search_categories"))
        );
      }
    },
  });
});
