import {
  aboutPath,
  activityPathForUser,
  adminManageUserPathForUser,
  badgesPathForUser,
  invitedPathForUser,
  messagesPathForUser,
  notificationsPathForUser,
  preferencesPathForUser,
  profileSummaryPathForUser,
} from "./fomio-mobile-nav-paths";

function normalizePath(path) {
  return path?.replace(/\/+$/, "") || "/";
}

function matchesExactPath(currentPath, ...patterns) {
  const path = normalizePath(currentPath);

  return patterns.some((pattern) => {
    if (!pattern) {
      return false;
    }

    return path === normalizePath(pattern);
  });
}

function matchesPath(currentPath, ...patterns) {
  const path = normalizePath(currentPath);

  return patterns.some((pattern) => {
    if (!pattern) {
      return false;
    }

    const normalizedPattern = normalizePath(pattern);
    if (normalizedPattern.endsWith("*")) {
      return path.startsWith(normalizedPattern.slice(0, -1));
    }

    return (
      path === normalizedPattern || path.startsWith(`${normalizedPattern}/`)
    );
  });
}

function canShowActivity({ currentUser, siteSettings }) {
  const viewingSelf = true;
  return (
    viewingSelf ||
    currentUser?.admin ||
    !siteSettings?.hide_user_activity_tab
  );
}

function canShowNotifications({ currentUser }) {
  const viewingSelf = true;
  return viewingSelf || currentUser?.admin;
}

function canShowMessages({ currentUser }) {
  const viewingSelf = true;
  return Boolean(
    currentUser?.can_send_private_messages &&
      (viewingSelf || currentUser?.admin)
  );
}

function canShowInvites({ currentUser }) {
  return Boolean(currentUser?.can_invite_to_forum);
}

function canShowPreferences({ currentUser }) {
  return currentUser?.can_edit !== false;
}

function canShowManageUser({ currentUser }) {
  return Boolean(currentUser?.staff);
}

export function getFomioCoreAccountSections(context) {
  const { currentUser, currentPath } = context;
  const username = currentUser?.username;
  const profileBasePath = username ? `/u/${username}` : null;
  const manageUserPath = adminManageUserPathForUser(currentUser);

  return [
    {
      key: "summary",
      icon: "user",
      labelKey: "mobile_nav.me_hub_summary",
      href: profileSummaryPathForUser(currentUser),
      isVisible: Boolean(profileSummaryPathForUser(currentUser)),
      isActive:
        matchesExactPath(currentPath, "/my", "/my/summary") ||
        matchesPath(
        currentPath,
          `${profileBasePath}/summary`
        ),
    },
    {
      key: "activity",
      icon: "bars-staggered",
      labelKey: "mobile_nav.me_hub_activity",
      href: activityPathForUser(currentUser),
      isVisible: canShowActivity(context),
      isActive: matchesPath(
        currentPath,
        `${profileBasePath}/activity*`,
        "/my/activity*"
      ),
    },
    {
      key: "notifications",
      icon: "bell",
      labelKey: "mobile_nav.me_hub_notifications",
      href: notificationsPathForUser(currentUser),
      isVisible: canShowNotifications(context),
      isActive: matchesPath(
        currentPath,
        "/notifications",
        "/notifications/*",
        `${profileBasePath}/notifications*`,
        "/my/notifications*"
      ),
    },
    {
      key: "messages",
      icon: "envelope",
      labelKey: "mobile_nav.me_hub_messages",
      href: messagesPathForUser(currentUser),
      isVisible: canShowMessages(context),
      isActive: matchesPath(
        currentPath,
        `${profileBasePath}/messages*`,
        "/my/messages*"
      ),
    },
    {
      key: "invites",
      icon: "user-plus",
      labelKey: "mobile_nav.me_hub_invites",
      href: invitedPathForUser(currentUser),
      isVisible: canShowInvites(context),
      isActive: matchesPath(currentPath, `${profileBasePath}/invited*`),
    },
    {
      key: "preferences",
      icon: "gear",
      labelKey: "mobile_nav.me_hub_preferences",
      href: preferencesPathForUser(currentUser),
      isVisible: canShowPreferences(context),
      isActive: matchesPath(
        currentPath,
        `${profileBasePath}/preferences*`,
        "/my/preferences*"
      ),
    },
    {
      key: "manage-user",
      icon: "wrench",
      labelKey: "mobile_nav.me_hub_admin",
      href: manageUserPath,
      isVisible: canShowManageUser(context),
      isActive: matchesPath(currentPath, `${manageUserPath}*`),
    },
  ].filter((section) => section.isVisible && section.href);
}

export function getFomioAuxiliaryMeSections(context) {
  const { currentUser, siteSettings } = context;

  return [
    {
      key: "badges",
      icon: "certificate",
      labelKey: "mobile_nav.me_hub_badges",
      href: badgesPathForUser(currentUser),
      isVisible: Boolean(
        siteSettings?.enable_badges && (currentUser?.badge_count ?? 0) > 0
      ),
    },
    {
      key: "about",
      icon: "book",
      labelKey: "mobile_nav.me_hub_about",
      href: aboutPath(),
      isVisible: true,
    },
    {
      key: "sign-out",
      icon: "sign-out",
      labelKey: "mobile_nav.me_hub_sign_out",
      href: currentUser ? "/logout" : null,
      isVisible: Boolean(currentUser),
      isMuted: true,
    },
  ].filter((section) => section.isVisible && section.href);
}
