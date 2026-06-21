// Pure mapping from the native UserSummary model (UserSummarySerializer) to the
// editorial hero's display rows. Kept free of Discourse imports so it is unit
// testable under `node --test`.
//
// Field mapping (Fomio terminology → Discourse serializer field):
//   bytes    → topic_count
//   replies  → post_count
//   received → likes_received
//   given    → likes_given

const STAT_DEFINITIONS = [
  { key: "bytes", field: "topic_count", labelKey: "profile_hero.bytes", pluralize: true },
  { key: "replies", field: "post_count", labelKey: "profile_hero.replies", pluralize: true },
  { key: "received", field: "likes_received", labelKey: "profile_hero.received", pluralize: false },
  { key: "given", field: "likes_given", labelKey: "profile_hero.given", pluralize: false },
];

function toCount(value) {
  return Number.isFinite(value) ? value : 0;
}

// Compact "1.2k" style formatter, mirroring fmtK in fomio-hub-chrome.gjs.
export function formatStatValue(value) {
  const n = toCount(value);
  return n >= 1000 ? (n / 1000).toFixed(1).replace(/\.0$/, "") + "k" : String(n);
}

// Top terets (categories) as bar-chart rows for the Summary section. Each row's
// `count` is total activity (topics + replies); `pct` is that count scaled to
// the busiest teret (0–100) so the bars read as a relative chart. Mirrors the
// prototype's "Top terets" block. Pure (no Ember imports) for unit testing.
export function profileTopTerets(model = {}, limit = 6) {
  const categories = model?.top_categories;
  if (!Array.isArray(categories)) {
    return [];
  }

  const rows = (limit > 0 ? categories.slice(0, limit) : categories.slice()).map(
    (category) => ({
      id: category?.id,
      name: category?.name || "",
      color: category?.color ? `#${category.color}` : null,
      count: toCount(category?.topic_count) + toCount(category?.post_count),
    })
  );

  const max = rows.reduce((peak, row) => Math.max(peak, row.count), 0);
  return rows.map((row) => ({
    ...row,
    pct: max > 0 ? Math.round((row.count / max) * 100) : 0,
  }));
}

// Returns the four hero stat descriptors. Always returns all four (zero-filled)
// so the row layout is stable across users.
export function profileSummaryStats(model = {}) {
  const source = model || {};
  return STAT_DEFINITIONS.map(({ key, field, labelKey, pluralize }) => {
    const count = toCount(source[field]);
    return {
      key,
      labelKey,
      pluralize,
      count,
      formatted: formatStatValue(count),
    };
  });
}
