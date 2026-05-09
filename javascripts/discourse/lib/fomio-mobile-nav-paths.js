// Shared path classification for mobile tab bar + contextual pills.
// Keep AUTH_PATHS in sync with fomio-layout.gjs and fomio-sidebar.gjs.

export const AUTH_PATH_PREFIXES = [
  "/login",
  "/signup",
  "/session/",
  "/user-api-key",
  "/password-reset",
  "/u/activate-account",
  "/u/account-created",
  "/invites",
  "/u/confirm",
  "/auth/",
];

export function isAuthPath(url) {
  return AUTH_PATH_PREFIXES.some((p) => url.startsWith(p));
}

/**
 * Canonical logged-in bookmarks URL. Prefer `/u/:username/activity/bookmarks`;
 * fall back to Discourse `/my/activity/bookmarks` if `username` is missing.
 */
export function bookmarksPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/activity/bookmarks`;
  }
  if (typeof console !== "undefined" && console.warn) {
    console.warn(
      "[Fomio] bookmarksPathForUser: missing username; using /my/activity/bookmarks"
    );
  }
  return "/my/activity/bookmarks";
}

export function profileSummaryPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/summary`;
  }
  if (typeof console !== "undefined" && console.warn) {
    console.warn(
      "[Fomio] profileSummaryPathForUser: missing username; using /my"
    );
  }
  return "/my";
}

export function activityPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/activity`;
  }
  return "/my/activity";
}

/**
 * Private messages inbox. Discourse’s canonical route is `/my/messages`.
 * Avoid `/u/:username/messages` here — not all sites expose it the same way,
 * and it risks `/u/undefined/messages` if username is ever missing.
 */
export function messagesPathForUser(user) {
  if (!user) {
    return null;
  }
  return "/my/messages";
}

/**
 * Account preferences (native Discourse `/my/preferences`).
 */
export function preferencesPathForUser(user) {
  if (!user) {
    return null;
  }
  return "/my/preferences";
}

/**
 * Notifications index for the current user. Discourse exposes this at `/notifications`
 * (see also `/u/:username/notifications`; we use the session-scoped canonical path).
 */
export function notificationsPathForUser(user) {
  if (!user) {
    return null;
  }
  return "/notifications";
}

/**
 * Site About page (native Discourse `/about`). Return null from a fork if the route is disabled.
 */
export function aboutPath() {
  return "/about";
}

/**
 * Touch Me hub: show on own account routes, `/my/*`, and `/notifications` (logged in);
 * logged out: any Me tab territory except bookmarks (sign-in callout).
 */
export function isMeHubSurfacePath(path, currentUser) {
  const p = path.split("?")[0];
  if (isAuthPath(p) || isSavedPath(path)) {
    return false;
  }
  if (!currentUser) {
    return isMePath(path);
  }
  if (p === "/notifications" || p.startsWith("/notifications/")) {
    return true;
  }
  if (p === "/my" || p.startsWith("/my/")) {
    return true;
  }
  const m = /^\/u\/([^/]+)/.exec(p);
  if (!m || !currentUser.username) {
    return false;
  }
  return m[1].toLowerCase() === currentUser.username.toLowerCase();
}

/**
 * Touch Me *landing* only: own profile summary entry (Fomio hub owns the screen).
 * Stack leaves (activity, bookmarks, preferences, notifications, …) return false.
 */
export function isMeLandingPath(path, currentUser) {
  const p = path.split("?")[0];
  if (!currentUser || isAuthPath(p) || isSavedPath(path)) {
    return false;
  }
  if (p === "/my" || p === "/my/summary") {
    return true;
  }
  const slug = currentUser.username;
  if (!slug) {
    return false;
  }
  const lower = slug.toLowerCase();
  const mSummary = /^\/u\/([^/]+)\/summary$/.exec(p);
  if (mSummary && mSummary[1].toLowerCase() === lower) {
    return true;
  }
  const mRoot = /^\/u\/([^/]+)$/.exec(p);
  if (mRoot && mRoot[1].toLowerCase() === lower) {
    return true;
  }
  return false;
}

/**
 * Home tab + home feed pills: primary reading feeds.
 */
export function isHomeFeedPath(path) {
  const p = path.split("?")[0];
  if (p === "/categories" || p.startsWith("/c/")) {
    return false;
  }
  if (p.includes("bookmarks")) {
    return false;
  }
  if (p.startsWith("/u/") || p === "/my" || p.startsWith("/my/")) {
    return false;
  }
  if (p.startsWith("/t/")) {
    return false;
  }
  if (p.startsWith("/search")) {
    return false;
  }
  if (p.startsWith("/notifications")) {
    return false;
  }
  return (
    p === "/" ||
    p.startsWith("/latest") ||
    p.startsWith("/hot") ||
    p.startsWith("/new") ||
    p.startsWith("/unread") ||
    p.startsWith("/top")
  );
}

export function isDiscoverPath(path) {
  const p = path.split("?")[0];
  return p === "/categories" || p.startsWith("/c/");
}

export function isSavedPath(path) {
  return path.split("?")[0].includes("bookmarks");
}

export function isMePath(path) {
  const p = path.split("?")[0];
  if (p.includes("bookmarks")) {
    return false;
  }
  if (p === "/notifications" || p.startsWith("/notifications/")) {
    return true;
  }
  if (p === "/my" || p.startsWith("/my/")) {
    return true;
  }
  return p.startsWith("/u/");
}
