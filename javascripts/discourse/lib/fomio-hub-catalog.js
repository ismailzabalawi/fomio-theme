export const FOMIO_TOP_LEVEL_HUB_LIMIT = 10;

export function normalizeCategorySource(source) {
  if (!source) {
    return [];
  }

  if (Array.isArray(source)) {
    return source;
  }

  if (typeof source.toArray === "function") {
    const normalized = source.toArray();
    return Array.isArray(normalized) ? normalized : [];
  }

  if (Array.isArray(source.content)) {
    return source.content;
  }

  if (typeof source.length === "number") {
    try {
      return Array.from(source);
    } catch {
      return [];
    }
  }

  return [];
}

export function dedupeCategories(categories) {
  const seen = new Set();

  return categories.filter((category) => {
    const key = category?.id ?? category?.slug;
    if (!key || seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  });
}

export function buildFomioHubCatalog(sources, options = {}) {
  const limit = options.limit ?? FOMIO_TOP_LEVEL_HUB_LIMIT;
  const rawCategories = sources
    .flatMap((source) => normalizeCategorySource(source))
    .filter((category) => Boolean(category && typeof category === "object"));
  const categories = dedupeCategories(rawCategories);
  const topLevelCandidates = categories.filter(
    (category) =>
      category &&
      (category.parent_category_id === null ||
        category.parent_category_id === undefined) &&
      category.slug !== "uncategorized"
  );

  return {
    categories,
    allTopLevelHubs: topLevelCandidates,
    topLevelHubs: topLevelCandidates.slice(0, limit),
    hasMoreHubs: topLevelCandidates.length > limit,
  };
}
