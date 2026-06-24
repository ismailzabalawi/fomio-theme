export const FOMIO_ACTIVITY_SCREEN_CLASS = "fomio-activity-screen";

export const FOMIO_ACTIVITY_SCREEN_VARIANT_CLASSES = [
  "fomio-activity-screen--all",
  "fomio-activity-screen--topics",
  "fomio-activity-screen--replies",
  "fomio-activity-screen--read",
  "fomio-activity-screen--drafts",
  "fomio-activity-screen--pending",
  "fomio-activity-screen--likes-given",
  "fomio-activity-screen--bookmarks",
  "fomio-activity-screen--bookmarks-with-reminders",
];

function normalizedPath(url = "") {
  const path = url.split("#")[0].split("?")[0].replace(/\/+$/, "");
  return path || "/";
}

export function fomioActivityRouteKind(url = "") {
  const path = normalizedPath(url);
  const match = /^\/(?:u\/[^/]+|my)\/activity(?:\/([^/]+))?$/i.exec(path);

  if (!match) {
    return null;
  }

  return match[1] || "all";
}

export function fomioActivityRouteClass(url = "") {
  const kind = fomioActivityRouteKind(url);

  if (!kind) {
    return null;
  }

  return `fomio-activity-screen--${kind.replace(/[^a-z0-9-]/gi, "-").toLowerCase()}`;
}

export function isFomioActivityMockupPath(url = "") {
  return Boolean(fomioActivityRouteKind(url));
}

export function isFomioActivityStreamPath(url = "") {
  return Boolean(fomioActivityRouteKind(url)) && !isFomioActivityTopicsPath(url);
}

export function isFomioActivityTopicsPath(url = "") {
  return [
    "topics",
    "read",
    "bookmarks",
    "bookmarks-with-reminders",
  ].includes(fomioActivityRouteKind(url));
}
