/**
 * Pure, framework-free derivations for the composer right rail + status bar.
 *
 * Kept dependency-free so it can be unit-tested with `node --test` and reused
 * by connectors. NOTE (per apps/web/CLAUDE.md): lib files must not import other
 * lib files — this module imports nothing and is imported only by compiled
 * entry points (connectors) and tests.
 */

export const RECOMMENDED_MIN = 600;
export const RECOMMENDED_MAX = 1200;
export const MIN_CHARS = 280;
export const WORDS_PER_MINUTE = 200;

/** Count whitespace-delimited words. Null/blank → 0. */
export function countWords(text) {
  if (!text) {
    return 0;
  }
  const matches = String(text).trim().match(/\S+/g);
  return matches ? matches.length : 0;
}

/** Total character count (raw). Null → 0. */
export function countChars(text) {
  return text ? String(text).length : 0;
}

/** Estimated read time in whole minutes; 0 words → 0, otherwise ≥ 1. */
export function readTimeMinutes(words, wpm = WORDS_PER_MINUTE) {
  if (!words || words <= 0) {
    return 0;
  }
  return Math.max(1, Math.ceil(words / wpm));
}

/**
 * Normalise raw heading descriptors into `[{ level, text }]`, dropping
 * blank entries. Accepts `[{ level, text }]`.
 */
export function extractOutline(headings) {
  if (!Array.isArray(headings)) {
    return [];
  }
  return headings
    .filter((h) => h && typeof h.text === "string" && h.text.trim())
    .map((h) => ({
      level: Number(h.level) > 0 ? Number(h.level) : 1,
      text: h.text.trim(),
    }));
}

/** Editorial readiness checks for the rail. */
export function computeChecks({ title, categoryId, chars } = {}) {
  return {
    titleSet: Boolean(title && String(title).trim()),
    teretChosen: categoryId !== null && categoryId !== undefined,
    minLength: (chars || 0) >= MIN_CHARS,
  };
}

/**
 * Progress toward the recommended upper word bound, clamped to 0–100.
 * Monotonic and saturating — the meter never exceeds 100%.
 */
export function progressPct(words, { max = RECOMMENDED_MAX } = {}) {
  if (!words || words <= 0) {
    return 0;
  }
  const pct = Math.round((words / max) * 100);
  return Math.max(0, Math.min(100, pct));
}
