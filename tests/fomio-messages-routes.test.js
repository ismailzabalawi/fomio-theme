import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  conversationListUrl,
  groupMessagesPath,
  parseFomioMessagesPath,
  preservePreviewTheme,
  userMessagesPath,
} from "../javascripts/discourse/lib/fomio-messages-routes.js";

describe("fomio-messages-routes", () => {
  it("maps Discourse user message routes to Fomio inbox filters", () => {
    assert.deepEqual(parseFomioMessagesPath("/u/ismail/messages"), {
      isMessagesPath: true,
      filter: "inbox",
      inbox: "user",
      groupName: null,
      tagName: null,
    });

    assert.equal(parseFomioMessagesPath("/u/ismail/messages/unread").filter, "unread");
    assert.equal(parseFomioMessagesPath("/u/ismail/messages/sent").filter, "sent");
    assert.equal(parseFomioMessagesPath("/u/ismail/messages/archive").filter, "inbox");
  });

  it("recognizes group inbox and tag routes without exposing topic language", () => {
    const groupRoute = parseFomioMessagesPath(
      "/u/ismail/messages/group/Design%20Moderators/unread"
    );

    assert.equal(groupRoute.filter, "groups");
    assert.equal(groupRoute.inbox, "group");
    assert.equal(groupRoute.groupName, "Design Moderators");
    assert.equal(groupRoute.groupFilter, "unread");

    const tagRoute = parseFomioMessagesPath("/u/ismail/messages/tags/support");
    assert.equal(tagRoute.inbox, "tag");
    assert.equal(tagRoute.tagName, "support");
  });

  it("builds canonical inbox paths and Discourse JSON endpoints", () => {
    assert.equal(userMessagesPath("Ismail", "inbox"), "/u/Ismail/messages");
    assert.equal(userMessagesPath("Ismail", "sent"), "/u/Ismail/messages/sent");
    assert.equal(
      groupMessagesPath("Ismail", "Design Moderators"),
      "/u/Ismail/messages/group/Design%20Moderators"
    );
    assert.equal(
      preservePreviewTheme("/u/Ismail/messages", "?preview_theme_id=33"),
      "/u/Ismail/messages?preview_theme_id=33"
    );

    assert.equal(
      conversationListUrl({ username: "Ismail", filter: "inbox" }),
      "/topics/private-messages/Ismail.json?page=0"
    );
    assert.equal(
      conversationListUrl({ username: "Ismail", filter: "sent" }),
      "/topics/private-messages-sent/Ismail.json?page=0"
    );
    assert.equal(
      conversationListUrl({
        username: "Ismail",
        filter: "unread",
        inbox: "group",
        groupName: "Design Moderators",
      }),
      "/topics/private-messages-group/Ismail/Design%20Moderators/unread.json?page=0"
    );
  });
});
