export {
  AUTH_PATH_PREFIXES,
  DISCOURSE_NATIVE_PATH_PREFIXES,
  isAuthPath,
  isDiscourseNativePath,
  isFomioShellPath,
  normalizePath,
} from "./fomio-route-mode.js";

import { isAuthPath, normalizePath } from "./fomio-route-mode.js";

function userPathMatcher(path) {
  const normalizedPath = normalizePath(path);
  const match = /^\/u\/([^/]+)(\/.*)?$/.exec(normalizedPath);
  if (!match) {
    return null;
  }

  return {
    username: match[1],
    isRoot: !match[2],
    suffix: match[2] || "",
  };
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
      "[Fomio] profileSummaryPathForUser: missing username; no safe fallback"
    );
  }
  return null;
}

export function meHubPathForUser(user) {
  if (!user) {
    return null;
  }

  if (user.username) {
    return `/u/${user.username}`;
  }

  return null;
}

export function shouldUseOwnProfileRootAsMeHub(currentUser, viewedUsername, { isTouchShell = false } = {}) {
  if (!isTouchShell || !currentUser?.username || !viewedUsername) {
    return false;
  }

  return (
    String(currentUser.username).toLowerCase() ===
    String(viewedUsername).toLowerCase()
  );
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

export function activityTopicsPathForUser(user) {
  const base = activityPathForUser(user);
  return base ? `${base}/topics` : null;
}

export function activityRepliesPathForUser(user) {
  const base = activityPathForUser(user);
  return base ? `${base}/replies` : null;
}

export function activityReadPathForUser(user) {
  const base = activityPathForUser(user);
  return base ? `${base}/read` : null;
}

export function activityLikesGivenPathForUser(user) {
  const base = activityPathForUser(user);
  return base ? `${base}/likes-given` : null;
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

export function preferencesMenuPathForUser(user) {
  const base = preferencesPathForUser(user);
  return base ? `${base}?fomio_menu=1` : null;
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
  return "/my/notifications";
}

export function notificationsRepliesPathForUser(user) {
  const base = notificationsPathForUser(user);
  return base ? `${base}/responses` : null;
}

export function notificationsMentionsPathForUser(user) {
  const base = notificationsPathForUser(user);
  return base ? `${base}/mentions` : null;
}

export function notificationsLikesPathForUser(user) {
  const base = notificationsPathForUser(user);
  return base ? `${base}/likes-received` : null;
}

export function preferencesNotificationsPathForUser(user) {
  if (!user) {
    return null;
  }
  if (user.username) {
    return `/u/${user.username}/preferences/notifications`;
  }
  return "/my/preferences/notifications";
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
 * Check if the current path is viewing the user's own messages.
 * Handles both `/u/:username/messages` and `/my/messages` patterns.
 */
export function isOwnMessagesPath(path, user) {
  if (!user?.username) {
    return false;
  }
  const normalizedPath = normalizePath(path).toLowerCase();
  const username = user.username.toLowerCase();
  return (
    normalizedPath.startsWith(`/u/${username}/messages`) ||
    normalizedPath.startsWith("/my/messages")
  );
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

export function adminManageUserPathForUsers(viewer, viewedUser) {
  if (!viewer?.staff || viewedUser?.id == null || !viewedUser?.username) {
    return null;
  }

  return `/admin/users/${viewedUser.id}/${String(viewedUser.username).toLowerCase()}`;
}

/**
 * Site About page (native Discourse `/about`). Return null from a fork if the route is disabled.
 */
export function aboutPath() {
  return "/about";
}

function ownUserPathMatcher(path, currentUser) {
  if (!currentUser?.username) {
    return null;
  }

  const slug = currentUser.username.toLowerCase();
  const match = userPathMatcher(path);
  if (!match || match.username.toLowerCase() !== slug) {
    return null;
  }

  return {
    isRoot: match.isRoot,
    suffix: match.suffix,
  };
}

export function viewedProfileUsername(path) {
  return userPathMatcher(path)?.username ?? null;
}

export function isUserProfilePath(path) {
  return Boolean(userPathMatcher(path));
}

export function isPathForCurrentUser(path, currentUser) {
  return Boolean(ownUserPathMatcher(normalizePath(path), currentUser));
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
    return isMePath(path, currentUser);
  }

  if (path === "/my/preferences" || path.startsWith("/my/preferences/")) {
    return false;
  }
  if (path === "/my/messages" || path.startsWith("/my/messages/")) {
    return false;
  }
  if (path.startsWith("/my/")) {
    return false;
  }

  const ownMatch = ownUserPathMatcher(path, currentUser);
  return Boolean(ownMatch && ownMatch.isRoot);
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
  const ownMatch = ownUserPathMatcher(p, currentUser);
  return Boolean(ownMatch && ownMatch.isRoot);
}

/**
 * Own profile routes that render Discourse's Summary (`body.user-summary-page`).
 * Excludes `/u/:username` without `/summary` so redirects / activity layouts are not matched.
 */
export function isOwnUserSummarySurfacePath(path, currentUser) {
  if (!currentUser) {
    return false;
  }
  const p = path.split("?")[0];
  const slug = currentUser.username;
  if (!slug) {
    return false;
  }
  const lower = slug.toLowerCase();
  const mSummary = /^\/u\/([^/]+)\/summary$/.exec(p);
  return Boolean(mSummary && mSummary[1].toLowerCase() === lower);
}

export function isOwnUserHubSurfacePath(path, currentUser) {
  if (!currentUser) {
    return false;
  }

  const p = normalizePath(path);
  const ownMatch = ownUserPathMatcher(p, currentUser);
  return Boolean(ownMatch && ownMatch.isRoot);
}

export function isOwnedProfileChildPath(path, currentUser) {
  const ownMatch = ownUserPathMatcher(normalizePath(path), currentUser);
  return Boolean(ownMatch && !ownMatch.isRoot);
}

/**
 * Home tab + home feed pills: primary reading feeds.
 */
export function isHomeFeedPath(path) {
  const p = normalizePath(path);
  if (p === "/categories" || p.startsWith("/c/")) {
    return false;
  }
  if (isSavedPath(p)) {
    return false;
  }
  if (p.startsWith("/u/") || p.startsWith("/my/")) {
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
  const p = normalizePath(path);
  return (
    p === "/categories" ||
    p.startsWith("/c/") ||
    p.startsWith("/top")
  );
}

export function isSavedPath(path) {
  const p = normalizePath(path);
  return (
    /^\/u\/[^/]+\/activity\/bookmarks(?:\/.*)?$/.test(p) ||
    /^\/my\/activity\/bookmarks(?:\/.*)?$/.test(p)
  );
}

export function isMePath(path, currentUser) {
  const p = normalizePath(path);
  if (isSavedPath(p)) {
    return false;
  }
  if (p === "/notifications" || p.startsWith("/notifications/")) {
    return true;
  }
  if (p.startsWith("/my/")) {
    return true;
  }
  return Boolean(ownUserPathMatcher(p, currentUser));
}

export function isOwnBookmarksPath(path, currentUser) {
  if (!currentUser) {
    return false;
  }

  const p = normalizePath(path);
  if (/^\/my\/activity\/bookmarks(?:\/.*)?$/.test(p)) {
    return true;
  }

  if (!currentUser.username) {
    return false;
  }

  const escapedUsername = String(currentUser.username).replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&"
  );

  return new RegExp(
    `^/u/${escapedUsername}/activity/bookmarks(?:/.*)?$`,
    "i"
  ).test(p);
}

export function isOwnNotificationsPath(path, currentUser) {
  if (!currentUser) {
    return false;
  }

  const p = normalizePath(path);
  if (p === "/notifications" || p.startsWith("/notifications/")) {
    return true;
  }
  if (p.startsWith("/my/notifications")) {
    return true;
  }

  if (!currentUser.username) {
    return false;
  }

  const escapedUsername = String(currentUser.username).replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&"
  );

  return new RegExp(`^/u/${escapedUsername}/notifications(?:/|$)`, "i").test(p);
}

export function isOwnProfileShellPath(path, currentUser) {
  return (
    isMePath(path, currentUser) && !isOwnNotificationsPath(path, currentUser)
  );
}

/**
 * True only when the user is at the Me Hub landing screen:
 * own-profile root (/u/:me).
 * All leaf pages (activity, preferences, notifications, …) return false.
 */
export function isMeHubPath(path, currentUser) {
  const p = normalizePath(path);
  if (isAuthPath(p) || isSavedPath(p)) {
    return false;
  }
  const ownMatch = ownUserPathMatcher(p, currentUser);
  return Boolean(ownMatch && ownMatch.isRoot);
}

/**
 * True when the user is on a Me leaf page (not the hub landing).
 * Used to show the Me stack header (← Me | Section Title).
 */
export function isMeStackPath(path, currentUser) {
  const p = normalizePath(path);
  if (!currentUser?.username) {
    return false;
  }

  return isMePath(path, currentUser) && !isMeHubPath(path, currentUser);
}

/**
 * Returns the i18n key suffix for the current Me section.
 * Used by fomio-me-stack-header to show the section title.
 * Returns null if the path is not a recognisable Me leaf.
 */
export function meSectionTitleKey(path) {
  const p = normalizePath(path);
  if (/^\/u\/[^/]+\/activity(\/|$)/.test(p) || p.startsWith("/my/activity")) {
    return "me_stack.activity";
  }
  if (
    /^\/u\/[^/]+\/notifications(\/|$)/.test(p) ||
    p === "/notifications" ||
    p.startsWith("/notifications/") ||
    p.startsWith("/my/notifications")
  ) {
    return "me_stack.notifications";
  }
  if (/^\/u\/[^/]+\/messages(\/|$)/.test(p) || p.startsWith("/my/messages")) {
    return "me_stack.messages";
  }
  if (
    /^\/u\/[^/]+\/preferences(\/|$)/.test(p) ||
    p.startsWith("/my/preferences")
  ) {
    return "me_stack.preferences";
  }
  if (/^\/u\/[^/]+\/invited(\/|$)/.test(p)) {
    return "me_stack.invites";
  }
  if (/^\/u\/[^/]+\/badges(\/|$)/.test(p)) {
    return "me_stack.badges";
  }
  return null;
}

export function isCoreActivityPath(path) {
  const p = normalizePath(path);
  return [
    /^\/u\/[^/]+\/activity$/,
    /^\/u\/[^/]+\/activity\/topics$/,
    /^\/u\/[^/]+\/activity\/replies$/,
    /^\/u\/[^/]+\/activity\/read$/,
    /^\/u\/[^/]+\/activity\/likes-given$/,
    /^\/my\/activity$/,
    /^\/my\/activity\/topics$/,
    /^\/my\/activity\/replies$/,
    /^\/my\/activity\/read$/,
    /^\/my\/activity\/likes-given$/,
  ].some((pattern) => pattern.test(p));
}

export function isActivityPath(path) {
  const p = normalizePath(path);
  return /^\/u\/[^/]+\/activity(\/|$)/.test(p) || p.startsWith("/my/activity");
}

export function isNotificationsPath(path) {
  const p = normalizePath(path);
  return (
    /^\/u\/[^/]+\/notifications(\/|$)/.test(p) ||
    p === "/notifications" ||
    p.startsWith("/notifications/") ||
    p.startsWith("/my/notifications")
  );
}
