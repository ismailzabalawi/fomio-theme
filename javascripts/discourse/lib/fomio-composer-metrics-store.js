import { TrackedObject } from "@ember-compat/tracked-built-ins";

/**
 * Reactive singleton holding live composer metrics. The ProseMirror metrics
 * extension writes here on each transaction; the rail + status-bar connectors
 * read it in tracked getters and re-render.
 *
 * This mirrors the mobile `messageBus` singleton pattern: a plain reactive
 * object that a non-Ember producer (the PM plugin) can write without needing
 * the Ember owner. Wiring is done in the api-initializer so no lib imports
 * another lib (per apps/web/CLAUDE.md).
 */
export const metricsStore = new TrackedObject({
  words: 0,
  chars: 0,
  outline: [],
  activeOutlinePos: null,
});

let outlineNavigator = null;

export function updateMetrics({
  words,
  chars,
  outline,
  activeOutlinePos,
  jumpToPos,
}) {
  if (typeof words === "number") {
    metricsStore.words = words;
  }
  if (typeof chars === "number") {
    metricsStore.chars = chars;
  }
  if (Array.isArray(outline)) {
    metricsStore.outline = outline;
  }
  if (activeOutlinePos === null || Number.isFinite(activeOutlinePos)) {
    metricsStore.activeOutlinePos = activeOutlinePos;
  }
  if (typeof jumpToPos === "function") {
    outlineNavigator = jumpToPos;
  }
}

export function resetMetrics() {
  metricsStore.words = 0;
  metricsStore.chars = 0;
  metricsStore.outline = [];
  metricsStore.activeOutlinePos = null;
  outlineNavigator = null;
}

export function jumpToOutline(pos) {
  if (typeof outlineNavigator !== "function") {
    return false;
  }
  return outlineNavigator(pos);
}
