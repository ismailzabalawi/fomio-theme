import { apiInitializer } from "discourse/lib/api";
import { groupComposerFormatting } from "../lib/fomio-composer-format";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  // Core only exposes this native control on mobile. The redesigned footer
  // already responds to showToolbar at every width; retain its action/state.
  api.modifyClass("component:composer-toggles", {
    pluginId: "fomio-composer-toolbar-toggle",

    get showToolbarToggle() {
      return (
        this.site.mobileView ||
        (this.composer.siteSettings.enable_composer_redesign &&
          this.args.composeState !== "draft" &&
          this.args.composeState !== "saving")
      );
    },
  });

  // Native commands and menu lifecycle, verified in the local Discourse.
  // No preference, site setting, editor content or submit action is changed.
  api.onToolbarCreate((toolbar) => {
    groupComposerFormatting(toolbar, {
      title: themePrefix("composer.format"),
      label: i18n(themePrefix("composer.format")),
    });
  });
});
