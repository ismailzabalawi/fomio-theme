import { apiInitializer } from "discourse/lib/api";
import { USER_OPTION_COMPOSITION_MODES } from "discourse/lib/constants";
import { themePrefix } from "virtual:theme";
import { installCanvasFocus } from "../lib/fomio-composer-canvas";
import {
  countChars,
  countWords,
  extractOutline,
} from "../lib/fomio-composer-metrics";
import { createMetricsExtension } from "../lib/fomio-composer-metrics-extension";
import {
  resetMetrics,
  updateMetrics,
} from "../lib/fomio-composer-metrics-store";
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

  // Live metrics for the rail + status bar. The pure (unit-tested) counting
  // functions are the single source of truth; the extension only extracts
  // text + headings from the ProseMirror doc.
  api.registerRichEditorExtension(
    createMetricsExtension({
      onUpdate: ({ text, headings }) =>
        updateMetrics({
          words: countWords(text),
          chars: countChars(text),
          outline: extractOutline(headings),
        }),
      onReset: resetMetrics,
    })
  );

  // Open-canvas behaviour: clicking the empty canvas on the full-page
  // Create / Edit surface focuses the editor and drops the caret at the end.
  if (typeof document !== "undefined") {
    installCanvasFocus(document);
  }
});
