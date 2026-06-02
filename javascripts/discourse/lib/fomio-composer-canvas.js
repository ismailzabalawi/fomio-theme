/**
 * "Open canvas" focus behaviour for the full-page Create / Edit composer.
 *
 * Clicking the empty canvas (the margins or the dead space below the text)
 * focuses the editor and drops the caret at the end — the Notion-style feel
 * of "the page is yours to write on", kept within Fomio's editorial surface.
 *
 * Mechanism is deliberately conservative: it focuses the same element core
 * focuses (`.d-editor-container .d-editor-input`, see composer service) and
 * places the caret with a standard DOM range that ProseMirror syncs. No
 * ProseMirror internals are touched. The decision is a pure function so it can
 * be unit-tested; only the thin DOM glue is runtime-only.
 *
 * NOTE (apps/web/CLAUDE.md): this lib imports nothing and is imported only by
 * the api-initializer entry point.
 */

// Structural wrappers that make up the canvas "dead space". A click landing
// directly on one of these (not on text, a field, or a control) is a canvas
// click.
export const CANVAS_SELECTORS = [
  ".reply-area",
  ".d-editor",
  ".d-editor-container",
  ".d-editor-textarea-column",
  ".d-editor-textarea-wrapper",
];

// Things inside the canvas that must keep their native click behaviour.
const INTERACTIVE_SELECTOR =
  "button, a, input, textarea, select, .select-kit, .fomio-composer-topbar, .fomio-composer-rail, .submit-panel, .d-editor-button-bar";

/**
 * Pure decision: should a canvas click move focus into the editor?
 * @param {object} flags
 * @param {boolean} flags.isOpen            composer is open
 * @param {boolean} flags.isFullPageMode    create or edit (not reply)
 * @param {boolean} flags.isCanvasSurface   target is a structural canvas wrapper
 * @param {boolean} flags.isInsideEditable  target is within the contenteditable
 * @param {boolean} flags.isInteractive     target is within a control/field
 * @returns {boolean}
 */
export function shouldFocusCanvas({
  isOpen,
  isFullPageMode,
  isCanvasSurface,
  isInsideEditable,
  isInteractive,
} = {}) {
  return Boolean(
    isOpen &&
      isFullPageMode &&
      isCanvasSurface &&
      !isInsideEditable &&
      !isInteractive
  );
}

function placeCaretAtEnd(input) {
  input.focus();

  const selection = window.getSelection?.();
  if (!selection || !input.lastChild) {
    return;
  }

  const range = document.createRange();
  range.selectNodeContents(input);
  range.collapse(false);
  selection.removeAllRanges();
  selection.addRange(range);
}

/**
 * Install the canvas-focus listener. Returns a cleanup function.
 * Delegates from the document (capture phase) so it works regardless of when
 * the composer mounts; every branch is guarded so it can never break a click.
 */
export function installCanvasFocus(root) {
  if (!root || typeof root.addEventListener !== "function") {
    return () => {};
  }

  const onMousedown = (event) => {
    try {
      const target = event.target;
      const replyControl = target?.closest?.("#reply-control");
      if (!replyControl) {
        return;
      }

      const flags = {
        isOpen: replyControl.classList.contains("open"),
        isFullPageMode:
          replyControl.classList.contains("composer-action-create-topic") ||
          replyControl.classList.contains("composer-action-edit"),
        isCanvasSurface: CANVAS_SELECTORS.some((sel) => target.matches?.(sel)),
        isInsideEditable: Boolean(target.closest?.(".d-editor-input")),
        isInteractive: Boolean(target.closest?.(INTERACTIVE_SELECTOR)),
      };

      if (!shouldFocusCanvas(flags)) {
        return;
      }

      const input = replyControl.querySelector(
        ".d-editor-container .d-editor-input"
      );
      if (!input) {
        return;
      }

      // Take over the dead-space click so focus + caret are deterministic.
      event.preventDefault();
      placeCaretAtEnd(input);
    } catch {
      // Never let canvas focusing interfere with normal interaction.
    }
  };

  root.addEventListener("mousedown", onMousedown, true);
  return () => root.removeEventListener("mousedown", onMousedown, true);
}
