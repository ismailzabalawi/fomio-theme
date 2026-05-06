import { apiInitializer } from "discourse/lib/api";
import { USER_OPTION_COMPOSITION_MODES } from "discourse/lib/constants";
import { themePrefix } from "virtual:theme";
import fomioSelectionToolbarExtension from "../lib/fomio-selection-toolbar-extension";

export default apiInitializer("1.8.0", (api) => {
  api.registerValueTransformer(
    "composer-force-editor-mode",
    ({ context }) => {
      if (!context?.model) {
        return null;
      }

      return USER_OPTION_COMPOSITION_MODES.rich;
    }
  );

  api.registerValueTransformer(
    "composer-editor-reply-placeholder",
    ({ value, context }) => {
      if (!context?.model) {
        return value;
      }

      return themePrefix("composer.rich_placeholder");
    }
  );

  api.registerRichEditorExtension(fomioSelectionToolbarExtension);
});
