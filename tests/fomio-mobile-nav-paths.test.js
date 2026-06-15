import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  getFomioCoreAccountSections,
  getFomioNotificationsChildSections,
  getFomioProfileMasterSections,
} from "../javascripts/discourse/lib/fomio-account-sections.js";
import {
  isAuthPath,
  isMeHubPath,
  isMeLandingSurfacePath,
  isOwnBookmarksPath,
  isOwnedProfileChildPath,
  isOwnNotificationsPath,
  isOwnProfileShellPath,
  preferencesMenuPathForUser,
  isSavedPath,
  isUserProfilePath,
  shouldUseOwnProfileRootAsMeHub,
  viewedProfileUsername,
} from "../javascripts/discourse/lib/fomio-mobile-nav-paths.js";
import { fomioCurrentPath } from "../javascripts/discourse/lib/fomio-router-pathname.js";
import {
  shouldHideSharedProfileHeader,
  shouldRenderInlineProfileIdentity,
} from "../javascripts/discourse/lib/fomio-profile-identity-ownership.js";
import {
  hasFomioPreferencesMenuMarker,
  isFomioPreferencesChildPath,
  isFomioPreferencesRootPath,
} from "../javascripts/discourse/lib/fomio-preferences-sections.js";

const currentUser = {
  id: 7,
  username: "Ismail",
  admin: false,
  staff: false,
  can_send_private_messages: true,
  can_edit: true,
  can_invite_to_forum: true,
};

describe("fomio-mobile-nav-paths", () => {
  it("prefers the live browser pathname when available", () => {
    const originalWindow = globalThis.window;
    globalThis.window = { location: { pathname: "/u/ismail" } };

    try {
      assert.equal(fomioCurrentPath("/u/ismail/activity"), "/u/ismail");
    } finally {
      globalThis.window = originalWindow;
    }
  });

  it("does not classify topic slugs containing bookmarks as saved routes", () => {
    const topicPath = "/t/how-bookmarks-work/123";

    assert.equal(isSavedPath(topicPath), false);
    assert.equal(isOwnBookmarksPath(topicPath, currentUser), false);
  });

  it("classifies canonical own-account sidebar routes correctly", () => {
    assert.equal(
      isOwnBookmarksPath("/u/ismail/activity/bookmarks", currentUser),
      true
    );
    assert.equal(
      isOwnNotificationsPath("/u/ismail/notifications/mentions", currentUser),
      true
    );
    assert.equal(
      isOwnProfileShellPath("/u/ismail/preferences/account", currentUser),
      true
    );
    assert.equal(isOwnedProfileChildPath("/u/ismail/messages", currentUser), true);
    assert.equal(isUserProfilePath("/u/other/activity"), true);
    assert.equal(viewedProfileUsername("/u/other/activity"), "other");
  });

  it("separates mobile preferences menu root from child form routes", () => {
    assert.equal(isFomioPreferencesRootPath("/my/preferences"), true);
    assert.equal(isFomioPreferencesRootPath("/my/preferences/"), true);
    assert.equal(isFomioPreferencesRootPath("/u/ismail/preferences"), true);
    assert.equal(isFomioPreferencesRootPath("/my/preferences/account"), false);

    assert.equal(isFomioPreferencesChildPath("/my/preferences/account"), true);
    assert.equal(
      isFomioPreferencesChildPath("/u/ismail/preferences/security"),
      true
    );
    assert.equal(isFomioPreferencesChildPath("/my/preferences"), false);
    assert.equal(
      hasFomioPreferencesMenuMarker("/u/ismail/preferences/account?fomio_menu=1"),
      true
    );
    assert.equal(hasFomioPreferencesMenuMarker("/my/preferences/account"), false);
    assert.equal(
      preferencesMenuPathForUser(currentUser),
      "/my/preferences?fomio_menu=1"
    );
  });

  it("does not classify another user's summary as an own-account shell route", () => {
    assert.equal(isOwnProfileShellPath("/u/other/summary", currentUser), false);
    assert.deepEqual(
      getFomioCoreAccountSections({
        currentUser,
        currentPath: "/u/other/summary",
        siteSettings: {},
      }),
      []
    );
  });

  it("treats own summary as a native profile route, not the touch me hub", () => {
    assert.equal(isMeLandingSurfacePath("/u/ismail/summary", currentUser), false);
    assert.equal(isMeHubPath("/u/ismail/summary", currentUser), false);
    assert.equal(isOwnProfileShellPath("/u/ismail/summary", currentUser), true);
  });

  it("keeps /u/:username as the dedicated touch me hub route", () => {
    assert.equal(isMeLandingSurfacePath("/u/ismail", currentUser), true);
    assert.equal(isMeHubPath("/u/ismail", currentUser), true);
  });

  it("only keeps the own profile root as a me hub on touch", () => {
    assert.equal(
      shouldUseOwnProfileRootAsMeHub(currentUser, "ismail", {
        isTouchShell: true,
      }),
      true
    );
    assert.equal(
      shouldUseOwnProfileRootAsMeHub(currentUser, "ismail", {
        isTouchShell: false,
      }),
      false
    );
    assert.equal(
      shouldUseOwnProfileRootAsMeHub(currentUser, "other", {
        isTouchShell: true,
      }),
      false
    );
  });

  it("does not render inline profile identity once parent/master owns it", () => {
    assert.equal(
      shouldRenderInlineProfileIdentity({
        currentPath: "/u/ismail",
        viewedUser: currentUser,
      }),
      false
    );

    assert.equal(
      shouldRenderInlineProfileIdentity({
        currentPath: "/u/ismail/summary",
        viewedUser: currentUser,
      }),
      false
    );
  });

  it("hides the shared header only where parent/master owns profile identity", () => {
    assert.equal(
      shouldHideSharedProfileHeader({
        currentPath: "/u/ismail",
        currentUser,
        isTouchShell: true,
      }),
      true
    );
    assert.equal(
      shouldHideSharedProfileHeader({
        currentPath: "/u/ismail/activity",
        currentUser,
        isTouchShell: true,
      }),
      true
    );
    assert.equal(
      shouldHideSharedProfileHeader({
        currentPath: "/u/other/activity",
        currentUser,
        isTouchShell: true,
      }),
      false
    );
    assert.equal(
      shouldHideSharedProfileHeader({
        currentPath: "/u/other/activity",
        currentUser,
        isTouchShell: false,
      }),
      true
    );
    assert.equal(
      shouldHideSharedProfileHeader({
        currentPath: "/login",
        currentUser,
        isTouchShell: false,
      }),
      false
    );
  });

  it("emits notifications panel links that match Discourse user notification routes", () => {
    const sections = getFomioNotificationsChildSections({
      currentUser,
      currentPath: "/u/ismail/notifications",
    });

    assert.deepEqual(
      sections.map((section) => [section.key, section.href]),
      [
        ["all", "/u/Ismail/notifications"],
        ["replies", "/u/Ismail/notifications/responses"],
        ["mentions", "/u/Ismail/notifications/mentions"],
        ["likes", "/u/Ismail/notifications/likes-received"],
        ["messages", "/u/Ismail/messages"],
        ["settings", "/u/Ismail/preferences/notifications"],
      ]
    );
    assert.equal(sections[0]?.isActive, true);
    assert.equal(sections[1]?.isActive, false);
  });

  it("marks the matching notifications panel link active on each sub-route", () => {
    const cases = [
      ["/u/ismail/notifications/responses", "replies"],
      ["/u/ismail/notifications/mentions", "mentions"],
      ["/u/ismail/notifications/likes-received", "likes"],
      ["/u/ismail/messages", "messages"],
      ["/u/ismail/preferences/notifications", "settings"],
    ];

    for (const [path, activeKey] of cases) {
      const sections = getFomioNotificationsChildSections({
        currentUser,
        currentPath: path,
      });
      const active = sections.filter((section) => section.isActive);

      assert.equal(
        active.length,
        1,
        `expected one active notifications panel link on ${path}`
      );
      assert.equal(active[0]?.key, activeKey);
    }
  });

  it("emits own-account sections with the mobile preferences menu entry", () => {
    const sections = getFomioCoreAccountSections({
      currentUser,
      currentPath: "/u/ismail/summary",
      siteSettings: {},
    });

    assert.deepEqual(
      sections.map((section) => [section.key, section.href]),
      [
        ["summary", "/u/Ismail/summary"],
        ["activity", "/u/Ismail/activity"],
        ["notifications", "/u/Ismail/notifications"],
        ["messages", "/u/Ismail/messages"],
        ["invites", "/u/Ismail/invited"],
        ["preferences", "/my/preferences?fomio_menu=1"],
      ]
    );
  });

  it("emits generic profile master sections for another user", () => {
    const viewedUser = {
      id: 2,
      username: "Soma",
      name: "Soma",
      badge_count: 3,
    };
    const staffViewer = {
      ...currentUser,
      admin: true,
      staff: true,
    };

    const sections = getFomioProfileMasterSections({
      currentUser: staffViewer,
      currentPath: "/u/soma/activity",
      siteSettings: { enable_badges: true, hide_user_activity_tab: false },
      viewedUser,
    });

    assert.equal(
      sections.some((section) => section.key === "preferences"),
      false
    );

    assert.deepEqual(
      sections.map((section) => [section.key, section.href]),
      [
        ["summary", "/u/Soma/summary"],
        ["activity", "/u/Soma/activity"],
        ["notifications", "/u/Soma/notifications"],
        ["messages", "/u/Soma/messages"],
        ["badges", "/u/Soma/badges"],
        ["manage-user", "/admin/users/2/soma"],
      ]
    );
  });
});
