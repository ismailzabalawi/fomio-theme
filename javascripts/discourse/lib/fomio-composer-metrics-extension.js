/**
 * Read-only ProseMirror extension that observes the rich editor and reports
 * raw text + heading descriptors to an injected callback. It performs NO
 * mutation and NO counting — the api-initializer wires the pure metrics
 * functions + store writer in (so no lib imports another lib).
 *
 * Hard rule (apps/web/CLAUDE.md): an extension that throws during editor setup
 * can freeze typing entirely. Every observer body is wrapped in try/catch and
 * fails silently.
 *
 * @param {object}   hooks
 * @param {(payload: {text: string, headings: {level:number,text:string,pos:number}[], cursorPos:number, jumpToPos: (pos:number)=>boolean}) => void} hooks.onUpdate
 * @param {() => void} [hooks.onReset]
 * @returns rich-editor extension object for `api.registerRichEditorExtension`
 */
export function createMetricsExtension({ onUpdate, onReset } = {}) {
  return {
    plugins: ({ pmState }) => {
      const { Plugin, TextSelection } = pmState;

      return new Plugin({
        view() {
          let editorView = null;

          const jumpToPos = (pos) => {
            try {
              if (!editorView || typeof pos !== "number") {
                return false;
              }

              const maxPos = editorView.state.doc.content.size;
              const clampedPos = Math.max(0, Math.min(pos, maxPos));
              const selection = TextSelection.create(
                editorView.state.doc,
                clampedPos
              );

              editorView.dispatch(
                editorView.state.tr.setSelection(selection).scrollIntoView()
              );
              editorView.focus();
              return true;
            } catch {
              return false;
            }
          };

          const report = (view) => {
            try {
              editorView = view;
              const { doc } = view.state;
              const text = doc.textBetween(0, doc.content.size, "\n", " ");

              const headings = [];
              doc.descendants((node, pos) => {
                if (node.type.name === "heading") {
                  headings.push({
                    level: node.attrs?.level ?? 1,
                    text: node.textContent,
                    pos,
                  });
                  return false;
                }
                return true;
              });

              onUpdate?.({
                text,
                headings,
                cursorPos: view.state.selection.from,
                jumpToPos,
              });
            } catch {
              // Never let metrics observation interfere with editing.
            }
          };

          return {
            update(view, prevState) {
              editorView = view;
              if (
                prevState &&
                prevState.doc.eq(view.state.doc) &&
                prevState.selection.eq(view.state.selection)
              ) {
                return;
              }
              report(view);
            },
            destroy() {
              editorView = null;
              try {
                onReset?.();
              } catch {
                // ignore
              }
            },
          };
        },
      });
    },
  };
}
