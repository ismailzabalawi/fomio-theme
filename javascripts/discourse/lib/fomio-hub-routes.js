export function normalizeHubFilter(rawUrl = "") {
  const url = rawUrl.split("?")[0];

  if (url.includes("/l/top")) {
    return "top";
  }

  if (url.includes("/l/new")) {
    return "new";
  }

  return "latest";
}

export function hubFilterSuffix(filter = "latest") {
  if (filter === "top") {
    return "/l/top";
  }

  if (filter === "new") {
    return "/l/new";
  }

  return "";
}

export function buildHubEntityUrl({ hub, teret = null, filter = "latest" }) {
  if (!hub?.slug || hub?.id == null) {
    return "";
  }

  const base = teret?.slug && teret?.id != null
    ? `/c/${hub.slug}/${teret.slug}/${teret.id}`
    : `/c/${hub.slug}/${hub.id}`;

  return `${base}${hubFilterSuffix(filter)}`;
}
