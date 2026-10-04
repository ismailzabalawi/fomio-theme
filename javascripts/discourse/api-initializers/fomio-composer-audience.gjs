import { apiInitializer } from "discourse/lib/api";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  // Core renders category.restricted in both the selection and menu badges.
  // Describe that existing indicator on the focusable composer control.
  api.modifyClass("component:category-chooser", {
    pluginId: "fomio-composer-category-visibility",

    didRender() {
      this._super(...arguments);
      if (!this.element?.closest("#reply-control")) {
        return;
      }

      const header = this.element.querySelector(".select-kit-header");
      if (!header) {
        return;
      }

      const restricted = Category.findById(this.value)?.read_restricted === true;
      if (restricted) {
        const label = i18n(themePrefix("composer.restricted_category"));
        header.setAttribute("title", label);
        header.setAttribute("aria-description", label);
        this._fomioVisibilityLabel = label;
      } else if (this._fomioVisibilityLabel) {
        for (const attribute of ["title", "aria-description"]) {
          if (header.getAttribute(attribute) === this._fomioVisibilityLabel) {
            header.removeAttribute(attribute);
          }
        }
        this._fomioVisibilityLabel = null;
      }
    },
  });
});
