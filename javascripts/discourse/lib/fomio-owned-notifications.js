const NOTIFICATIONS_PATH_RE = /^\/u\/([^/]+)\/notifications\/?$/i;

export const OWNED_NOTIFICATIONS_LIMIT = 60;

export function parseOwnedNotificationsRoute(currentUrl, currentUser = null) {
  const parsed = parseUrl(currentUrl);
  const path = parsed.pathname.replace(/\/+$/, "") || "/";
  const match = path.match(NOTIFICATIONS_PATH_RE);

  if (!match) {
    return {
      isIndex: false,
      username: null,
      filter: null,
    };
  }

  const username = decodeURIComponent(match[1]);

  if (
    currentUser?.username &&
    username.toLowerCase() !== String(currentUser.username).toLowerCase()
  ) {
    return {
      isIndex: false,
      username,
      filter: null,
    };
  }

  return {
    isIndex: true,
    username,
    filter: normalizeNotificationFilter(parsed.searchParams.get("filter")),
  };
}

export function normalizeNotificationFilter(filter) {
  return filter === "read" || filter === "unread" ? filter : null;
}

export function ownedNotificationsRequest(routeState, options = {}) {
  if (options.loadMoreUrl) {
    return {
      url: options.loadMoreUrl,
      data: null,
    };
  }

  const data = {
    username: routeState?.username,
    limit: options.limit ?? OWNED_NOTIFICATIONS_LIMIT,
  };

  if (routeState?.filter) {
    data.filter = routeState.filter;
  }

  return {
    url: "/notifications.json",
    data,
  };
}

export function ownedNotificationsFilterPath(routeState, currentUrl, filter) {
  const parsed = parseUrl(currentUrl);
  const path = routeState?.username
    ? `/u/${encodeURIComponent(routeState.username)}/notifications`
    : parsed.pathname;
  const params = new URLSearchParams(parsed.search);
  const normalizedFilter = normalizeNotificationFilter(filter);

  if (normalizedFilter) {
    params.set("filter", normalizedFilter);
  } else {
    params.delete("filter");
  }

  const queryString = params.toString();
  return queryString ? `${path}?${queryString}` : path;
}

export function normalizeOwnedNotificationsPayload(payload = {}) {
  return {
    notifications: Array.isArray(payload.notifications)
      ? payload.notifications
      : [],
    totalRows: Number.isFinite(payload.total_rows_notifications)
      ? payload.total_rows_notifications
      : null,
    loadMoreUrl: payload.load_more_notifications || null,
  };
}

function parseUrl(currentUrl) {
  try {
    return new URL(currentUrl || "/", "https://fomio.local");
  } catch {
    return new URL("/", "https://fomio.local");
  }
}
