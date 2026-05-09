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
 * Private messages inbox. Prefer per-user `/u/:username/messages` (matches user-nav);
 * fall back to `/my/messages` if `username` is missing.
 */
export function messagesPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/messages`;
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
 * User notifications (matches `user-nav` → `userNotifications`, `config/routes.rb`).
 */
export function notificationsPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/notifications`;
  }
  return "/notifications";
}

/**
 * Invites (`/u/:username/invited`).
 */
export function invitedPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/invited`;
  }
  return null;
}

/**
 * Badges (`/u/:username/badges`).
 */
export function badgesPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/badges`;
  }
  return null;
}

/**
 * Staff “Manage user” in admin (`/admin/users/:id/:username`).
 */
export function adminManageUserPathForUser(user) {
  if (!user?.staff || user.id == null || !user.username) {
    return null;
  }
  return `/admin/users/${user.id}/${String(user.username).toLowerCase()}`;
}

/**
 * Site About page (native Discourse `/about`). Return null from a fork if the route is disabled.
 */
export function aboutPath() {
  return "/about";
}

/**
 * Touch Me hub: only own profile landing surfaces (not native leaf routes).
 * Logged-out: Me-tab territory sign-in CTA (`isMePath`), excluding about/logout/session notifications.
 */
export function isMeLandingSurfacePath(rawUrl, currentUser) {
  const path = rawUrl.split("?")[0];
  if (isAuthPath(path) || isSavedPath(path)) {
    return false;
  }
  if (path === "/about" || path.startsWith("/about/")) {
    return false;
  }
  if (path === "/logout") {
    return false;
  }
  if (path === "/notifications" || path.startsWith("/notifications/")) {
    return false;
  }

  if (!currentUser) {
    return isMePath(path);
  }

  if (path === "/my/preferences" || path.startsWith("/my/preferences/")) {
    return false;
  }
  if (path === "/my/messages" || path.startsWith("/my/messages/")) {
    return false;
  }
  if (path === "/my" || path === "/my/summary") {
    return true;
  }
  if (path.startsWith("/my/")) {
    return false;
  }

  if (!currentUser.username) {
    return false;
  }
  const slug = currentUser.username.toLowerCase();
  const mSummary = /^\/u\/([^/]+)\/summary$/.exec(path);
  if (mSummary && mSummary[1].toLowerCase() === slug) {
    return true;
  }
  const mRoot = /^\/u\/([^/]+)$/.exec(path);
  if (mRoot && mRoot[1].toLowerCase() === slug) {
    return true;
  }
  return false;
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
  if (p.startsWith("/top")) {
    return false;
  }
  return (
    p === "/" ||
    p.startsWith("/latest") ||
    p.startsWith("/hot") ||
    p.startsWith("/new") ||
    p.startsWith("/unread")
  );
}

export function isDiscoverPath(path) {
  const p = path.split("?")[0];
  return (
    p === "/categories" ||
    p.startsWith("/c/") ||
    p.startsWith("/top")
  );
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
