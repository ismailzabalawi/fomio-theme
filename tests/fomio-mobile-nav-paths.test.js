import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  fomioActivityRouteClass,
  fomioActivityRouteKind,
  isFomioActivityBookmarksPath,
  isFomioActivityBytesPath,
  isFomioActivityM1TimelineRoute,
  isFomioActivityM2BytesRoute,
  isFomioActivityMockupPath,
  isFomioActivityPendingPath,
  isFomioActivityReadPath,
  isFomioActivityStreamPath,
  isFomioActivityTopicListPath,
  isFomioActivityTopicsPath,
} from "../javascripts/discourse/lib/fomio-activity-paths.js";
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
  hasFomioPreferencesMenuMarker,
  isFomioPreferencesChildPath,
  isFomioPreferencesPath,
  isFomioPreferencesRootPath,
} from "../javascripts/discourse/lib/fomio-preferences-sections.js";

describe("fomio-activity-paths", () => {
  it("recognizes native and plugin activity leaves for the activity shell", () => {
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity"), true);
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity/topics"), true);
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity/replies"), true);
    assert.equal(
      isFomioActivityMockupPath("/u/ismail/activity/likes-given"),
      true
    );
    assert.equal(isFomioActivityMockupPath("/my/activity"), true);
    assert.equal(isFomioActivityMockupPath("/my/activity?foo=1"), true);
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity/read"), true);
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity/drafts"), true);
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity/bookmarks"), true);
    assert.equal(isFomioActivityMockupPath("/u/ismail/activity/solved"), true);

    assert.equal(isFomioActivityMockupPath("/u/ismail/preferences"), false);
  });

  it("separates stream and topic-list activity routes", () => {
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity"), true);
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/replies"), true);
    assert.equal(
      isFomioActivityStreamPath("/u/ismail/activity/likes-given"),
      true
    );
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/topics"), false);
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/read"), false);
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/drafts"), true);
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/solved"), true);
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/pending"), true);
    assert.equal(isFomioActivityStreamPath("/u/ismail/activity/bookmarks"), false);

    assert.equal(isFomioActivityTopicListPath("/u/ismail/activity/topics"), true);
    assert.equal(isFomioActivityTopicListPath("/u/ismail/activity/read"), true);
    assert.equal(
      isFomioActivityTopicListPath("/u/ismail/activity/bookmarks"),
      true
    );
    assert.equal(isFomioActivityTopicListPath("/u/ismail/activity"), false);

    assert.equal(isFomioActivityBytesPath("/u/ismail/activity/topics"), true);
    assert.equal(isFomioActivityBytesPath("/my/activity/topics"), true);
    assert.equal(isFomioActivityBytesPath("/u/ismail/activity/read"), false);
    assert.equal(isFomioActivityBytesPath("/u/ismail/activity/bookmarks"), false);

    assert.equal(isFomioActivityTopicsPath("/u/ismail/activity/topics"), true);
    assert.equal(isFomioActivityTopicsPath("/u/ismail/activity/read"), false);
    assert.equal(isFomioActivityTopicsPath("/u/ismail/activity/bookmarks"), false);
    assert.equal(isFomioActivityTopicsPath("/u/ismail/activity"), false);

    assert.equal(isFomioActivityReadPath("/u/ismail/activity/read"), true);
    assert.equal(isFomioActivityReadPath("/u/ismail/activity/topics"), false);

    assert.equal(
      isFomioActivityBookmarksPath("/u/ismail/activity/bookmarks"),
      true
    );
    assert.equal(
      isFomioActivityBookmarksPath("/u/ismail/activity/bookmarks-with-reminders"),
      true
    );
    assert.equal(isFomioActivityBookmarksPath("/u/ismail/activity/topics"), false);

    assert.equal(isFomioActivityPendingPath("/u/ismail/activity/pending"), true);
    assert.equal(isFomioActivityPendingPath("/u/ismail/activity"), false);
  });

  it("returns the activity route kind used for body classes", () => {
    assert.equal(fomioActivityRouteKind("/u/ismail/activity"), "all");
    assert.equal(fomioActivityRouteKind("/u/ismail/activity/topics"), "topics");
    assert.equal(fomioActivityRouteKind("/u/ismail/activity/replies"), "replies");
    assert.equal(fomioActivityRouteKind("/u/ismail/activity/read"), "read");
    assert.equal(fomioActivityRouteKind("/u/ismail/activity/drafts"), "drafts");
    assert.equal(
      fomioActivityRouteKind("/u/ismail/activity/likes-given"),
      "likes-given"
    );
    assert.equal(fomioActivityRouteKind("/u/ismail/activity/pending"), "pending");
    assert.equal(fomioActivityRouteKind("/u/ismail/activity/solved"), "solved");
    assert.equal(
      fomioActivityRouteClass("/u/ismail/activity/bookmarks-with-reminders"),
      "fomio-activity-screen--bookmarks-with-reminders"
    );
  });

  it("gates M1 timeline connector routes", () => {
    assert.equal(isFomioActivityM1TimelineRoute("userActivity.index"), true);
    assert.equal(isFomioActivityM1TimelineRoute("userActivity.replies"), true);
    assert.equal(isFomioActivityM1TimelineRoute("userActivity.likesGiven"), true);
    assert.equal(isFomioActivityM1TimelineRoute("userActivity.drafts"), false);
    assert.equal(isFomioActivityM1TimelineRoute("userActivity.topics"), false);
    assert.equal(isFomioActivityM1TimelineRoute("userActivity.solved"), false);
  });

  it("gates M2 Bytes connector routes", () => {
    assert.equal(isFomioActivityM2BytesRoute("userActivity.topics"), true);
    assert.equal(isFomioActivityM2BytesRoute("userActivity.index"), false);
    assert.equal(isFomioActivityM2BytesRoute("userActivity.read"), false);
  });
});

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

  it("scopes the mobile preferences menu to the preferences area only", () => {
    // Root and child preferences routes are both inside the preferences area,
    // so a lingering menu marker can only ever resurface there.
    assert.equal(isFomioPreferencesPath("/my/preferences"), true);
    assert.equal(isFomioPreferencesPath("/u/ismail/preferences"), true);
    assert.equal(isFomioPreferencesPath("/my/preferences/account"), true);
    assert.equal(
      isFomioPreferencesPath("/u/ismail/preferences/security"),
      true
    );

    // Everything else is outside the preferences area. Even with a stale
    // sessionStorage menu marker set, the menu must not render on these.
    assert.equal(isFomioPreferencesPath("/"), false);
    assert.equal(isFomioPreferencesPath("/latest"), false);
    assert.equal(isFomioPreferencesPath("/u/ismail"), false);
    assert.equal(isFomioPreferencesPath("/u/ismail/activity"), false);
    assert.equal(isFomioPreferencesPath("/t/some-byte/123"), false);
  });

  it("does not classify another user's summary as an own-account shell route", () => {
    assert.equal(isOwnProfileShellPath("/u/other/summary", currentUser), false);
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
});
