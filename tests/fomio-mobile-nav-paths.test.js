import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { getFomioCoreAccountSections } from "../javascripts/discourse/lib/fomio-account-sections.js";
import {
  isOwnBookmarksPath,
  isOwnNotificationsPath,
  isOwnProfileShellPath,
  isSavedPath,
} from "../javascripts/discourse/lib/fomio-mobile-nav-paths.js";

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

  it("emits own-account sections with canonical URLs on owned surfaces", () => {
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
        ["preferences", "/my/preferences"],
      ]
    );
  });
});
