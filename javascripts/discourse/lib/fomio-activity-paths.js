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

const TOPIC_LIST_ACTIVITY_KINDS = [
  "topics",
  "read",
  "bookmarks",
  "bookmarks-with-reminders",
];

export function isFomioActivityTopicListPath(url = "") {
  const kind = fomioActivityRouteKind(url);
  return TOPIC_LIST_ACTIVITY_KINDS.includes(kind);
}

export function isFomioActivityStreamPath(url = "") {
  const kind = fomioActivityRouteKind(url);
  if (!kind) {
    return false;
  }

  return !isFomioActivityTopicListPath(url);
}

/** Bytes tab only (`/activity/topics`). */
export function isFomioActivityBytesPath(url = "") {
  return fomioActivityRouteKind(url) === "topics";
}

/** @deprecated Use isFomioActivityBytesPath — kept for call-site clarity during M2. */
export function isFomioActivityTopicsPath(url = "") {
  return isFomioActivityBytesPath(url);
}

export function isFomioActivityReadPath(url = "") {
  return fomioActivityRouteKind(url) === "read";
}

export function isFomioActivityBookmarksPath(url = "") {
  const kind = fomioActivityRouteKind(url);
  return kind === "bookmarks" || kind === "bookmarks-with-reminders";
}

export function isFomioActivityPendingPath(url = "") {
  return fomioActivityRouteKind(url) === "pending";
}

/** M1 timeline stream tabs only (All / Replies / Likes given). */
export function isFomioActivityM1TimelineRoute(routeName = "") {
  return [
    "userActivity.index",
    "userActivity.replies",
    "userActivity.likesGiven",
  ].includes(routeName);
}

/** M2 Bytes tab (`userActivity.topics`). */
export function isFomioActivityM2BytesRoute(routeName = "") {
  return routeName === "userActivity.topics";
}
