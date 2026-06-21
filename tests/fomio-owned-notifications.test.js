import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  normalizeNotificationFilter,
  normalizeOwnedNotificationsPayload,
  ownedNotificationsFilterPath,
  ownedNotificationsRequest,
  parseOwnedNotificationsRoute,
} from "../javascripts/discourse/lib/fomio-owned-notifications.js";

const currentUser = { username: "Soma" };

describe("fomio-owned-notifications", () => {
  it("parses the own notifications index route", () => {
    assert.deepEqual(
      parseOwnedNotificationsRoute(
        "/u/Soma/notifications?preview_theme_id=33",
        currentUser
      ),
      {
        isIndex: true,
        username: "Soma",
        filter: null,
      }
    );
  });

  it("keeps only read and unread as server filters", () => {
    assert.equal(normalizeNotificationFilter("read"), "read");
    assert.equal(normalizeNotificationFilter("unread"), "unread");
    assert.equal(normalizeNotificationFilter("all"), null);
    assert.equal(normalizeNotificationFilter("reactions"), null);
  });

  it("does not own notification action subroutes", () => {
    assert.equal(
      parseOwnedNotificationsRoute("/u/Soma/notifications/mentions", currentUser)
        .isIndex,
      false
    );
  });

  it("does not own another user's notifications", () => {
    assert.equal(
      parseOwnedNotificationsRoute("/u/Other/notifications", currentUser).isIndex,
      false
    );
  });

  it("builds the initial notifications request", () => {
    assert.deepEqual(
      ownedNotificationsRequest({
        isIndex: true,
        username: "Soma",
        filter: "unread",
      }),
      {
        url: "/notifications.json",
        data: {
          username: "Soma",
          limit: 60,
          filter: "unread",
        },
      }
    );
  });

  it("follows the server pagination URL as-is", () => {
    assert.deepEqual(
      ownedNotificationsRequest(null, {
        loadMoreUrl: "/notifications?offset=60&limit=60&username=Soma",
      }),
      {
        url: "/notifications?offset=60&limit=60&username=Soma",
        data: null,
      }
    );
  });

  it("preserves preview query params when changing read filters", () => {
    assert.equal(
      ownedNotificationsFilterPath(
        { username: "Soma" },
        "/u/Soma/notifications?preview_theme_id=33",
        "unread"
      ),
      "/u/Soma/notifications?preview_theme_id=33&filter=unread"
    );

    assert.equal(
      ownedNotificationsFilterPath(
        { username: "Soma" },
        "/u/Soma/notifications?preview_theme_id=33&filter=read",
        null
      ),
      "/u/Soma/notifications?preview_theme_id=33"
    );
  });

  it("normalizes the list payload", () => {
    assert.deepEqual(
      normalizeOwnedNotificationsPayload({
        notifications: [{ id: 1 }],
        total_rows_notifications: 12,
        load_more_notifications: "/notifications?offset=60",
      }),
      {
        notifications: [{ id: 1 }],
        totalRows: 12,
        loadMoreUrl: "/notifications?offset=60",
      }
    );
  });
});
