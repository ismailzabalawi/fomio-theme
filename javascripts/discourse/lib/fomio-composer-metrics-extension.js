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
 * @param {(payload: {text: string, headings: {level:number,text:string}[]}) => void} hooks.onUpdate
 * @param {() => void} [hooks.onReset]
 * @returns rich-editor extension object for `api.registerRichEditorExtension`
 */
export function createMetricsExtension({ onUpdate, onReset } = {}) {
  return {
    plugins: ({ pmState }) => {
      const { Plugin } = pmState;

      return new Plugin({
        view() {
          const report = (view) => {
            try {
              const { doc } = view.state;
              const text = doc.textBetween(0, doc.content.size, "\n", " ");

              const headings = [];
              doc.descendants((node) => {
                if (node.type.name === "heading") {
                  headings.push({
                    level: node.attrs?.level ?? 1,
                    text: node.textContent,
                  });
                  return false;
                }
                return true;
              });

              onUpdate?.({ text, headings });
            } catch {
              // Never let metrics observation interfere with editing.
            }
          };

          return {
            update(view, prevState) {
              if (prevState && prevState.doc.eq(view.state.doc)) {
                return;
              }
              report(view);
            },
            destroy() {
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
