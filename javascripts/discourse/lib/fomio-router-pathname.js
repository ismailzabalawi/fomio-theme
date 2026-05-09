/**
 * Pathname from Discourse `router.currentURL` (query stripped). Handles absolute
 * URLs so active-row logic matches `getURL()` hrefs. M2-H2 QA hardening.
 */
export function fomioPathnameNoQuery(currentURL) {
  const raw = (currentURL || "").split("?")[0] || "";
  if (raw.startsWith("http://") || raw.startsWith("https://")) {
    try {
      return new URL(raw).pathname;
    } catch {
      /* ignore */
    }
  }
  return raw;
}

/** Trailing-slash–agnostic, case-insensitive path compare (Discourse URLs are ASCII). */
export function fomioPathsEqual(a, b) {
  const norm = (x) => (x.replace(/\/$/, "") || "/").toLowerCase();
  return norm(a || "") === norm(b || "");
}
