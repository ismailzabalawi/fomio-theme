/**
 * Subscribe to body class changes + initial sync for fomio-surface-touch.
 * Used by touch-only connectors that must react when surface mode flips.
 */
export function subscribeFomioTouchShell(callback) {
  if (typeof document === "undefined" || !document.body) {
    return () => {};
  }

  const run = () => {
    callback(Boolean(document.body.classList.contains("fomio-surface-touch")));
  };

  run();

  const observer = new MutationObserver(run);
  observer.observe(document.body, {
    attributes: true,
    attributeFilter: ["class"],
  });

  return () => observer.disconnect();
}
