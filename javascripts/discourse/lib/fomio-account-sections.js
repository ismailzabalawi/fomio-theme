import {
  aboutPath,
  activityPathForUser,
  activityLikesGivenPathForUser,
  activityReadPathForUser,
  activityRepliesPathForUser,
  activityTopicsPathForUser,
  adminManageUserPathForUser,
  badgesPathForUser,
  invitedPathForUser,
  isCoreActivityPath,
  messagesPathForUser,
  notificationsLikesPathForUser,
  notificationsPathForUser,
  notificationsMentionsPathForUser,
  notificationsRepliesPathForUser,
  preferencesNotificationsPathForUser,
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
      metaKey: "mobile_nav.me_hub_notifications_meta",
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
      metaKey: "mobile_nav.me_hub_settings_meta",
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
      isAdminSection: true,
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

export function getFomioActivityChildSections(context) {
  const { currentUser, currentPath } = context;

  return [
    {
      key: "all",
      labelKey: "me_activity_nav.all",
      href: activityPathForUser(currentUser),
      isActive: matchesExactPath(currentPath, activityPathForUser(currentUser), "/my/activity"),
    },
    {
      key: "topics",
      labelKey: "me_activity_nav.topics",
      href: activityTopicsPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        activityTopicsPathForUser(currentUser),
        "/my/activity/topics"
      ),
    },
    {
      key: "replies",
      labelKey: "me_activity_nav.replies",
      href: activityRepliesPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        activityRepliesPathForUser(currentUser),
        "/my/activity/replies"
      ),
    },
    {
      key: "read",
      labelKey: "me_activity_nav.read",
      href: activityReadPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        activityReadPathForUser(currentUser),
        "/my/activity/read"
      ),
    },
    {
      key: "likes-given",
      labelKey: "me_activity_nav.likes_given",
      href: activityLikesGivenPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        activityLikesGivenPathForUser(currentUser),
        "/my/activity/likes-given"
      ),
    },
  ].filter((section) => section.href);
}

export function getFomioNotificationsChildSections(context) {
  const { currentUser, currentPath } = context;

  return [
    {
      key: "all",
      labelKey: "notifications_master_pane.all",
      href: notificationsPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        notificationsPathForUser(currentUser),
        "/notifications",
        "/my/notifications"
      ),
    },
    {
      key: "replies",
      labelKey: "notifications_master_pane.replies",
      href: notificationsRepliesPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        notificationsRepliesPathForUser(currentUser),
        "/my/notifications/responses"
      ),
    },
    {
      key: "mentions",
      labelKey: "notifications_master_pane.mentions",
      href: notificationsMentionsPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        notificationsMentionsPathForUser(currentUser),
        "/my/notifications/mentions"
      ),
    },
    {
      key: "likes",
      labelKey: "notifications_master_pane.likes",
      href: notificationsLikesPathForUser(currentUser),
      isActive: matchesExactPath(
        currentPath,
        notificationsLikesPathForUser(currentUser),
        "/my/notifications/likes-received"
      ),
    },
    {
      key: "messages",
      labelKey: "notifications_master_pane.messages",
      href: messagesPathForUser(currentUser),
      isActive: matchesPath(
        currentPath,
        messagesPathForUser(currentUser),
        "/my/messages*"
      ),
    },
    {
      key: "settings",
      labelKey: "notifications_master_pane.settings",
      href: preferencesNotificationsPathForUser(currentUser),
      isActive: matchesPath(
        currentPath,
        preferencesNotificationsPathForUser(currentUser),
        "/my/preferences/notifications*"
      ),
    },
  ].filter((section) => section.href);
}

export function isOwnedActivitySectionPath(currentPath) {
  return isCoreActivityPath(currentPath);
}
