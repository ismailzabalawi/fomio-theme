import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  normalizeOwnedActivityPayload,
  normalizeUserAction,
  ownedActivityRequest,
  parseOwnedActivityRoute,
} from "../javascripts/discourse/lib/fomio-owned-activity.js";

const currentUser = { username: "Soma" };

describe("fomio-owned-activity", () => {
  it("parses core own activity routes", () => {
    assert.deepEqual(
      parseOwnedActivityRoute("/u/Soma/activity?preview_theme_id=33", currentUser),
      { isActivity: true, username: "Soma", filter: "all", isSelf: true }
    );
    assert.deepEqual(
      parseOwnedActivityRoute("/u/Soma/activity/replies", currentUser),
      { isActivity: true, username: "Soma", filter: "replies", isSelf: true }
    );
    assert.deepEqual(parseOwnedActivityRoute("/my/activity/read", currentUser), {
      isActivity: true,
      username: "Soma",
      filter: "read",
      isSelf: true,
    });
  });

  it("owns another profile's public activity as a non-self timeline", () => {
    assert.deepEqual(
      parseOwnedActivityRoute("/u/Other/activity", currentUser),
      { isActivity: true, username: "Other", filter: "all", isSelf: false }
    );
    assert.deepEqual(
      parseOwnedActivityRoute("/u/Other/activity/likes-given", currentUser),
      { isActivity: true, username: "Other", filter: "likes-given", isSelf: false }
    );
  });

  it("does not own plugin routes or another profile's private read history", () => {
    assert.equal(
      parseOwnedActivityRoute("/u/Soma/activity/votes", currentUser).isActivity,
      false
    );
    assert.equal(
      parseOwnedActivityRoute("/u/Other/activity/read", currentUser).isActivity,
      false
    );
  });

  it("builds user-action requests for all, replies, and likes", () => {
    assert.deepEqual(
      ownedActivityRequest({ username: "Soma", filter: "all" }),
      {
        url: "/user_actions.json",
        data: {
          offset: 0,
          limit: 30,
          username: "Soma",
          filter: "4,5",
        },
      }
    );

    assert.equal(
      ownedActivityRequest({ username: "Soma", filter: "replies" }).data.filter,
      "5"
    );
    assert.equal(
      ownedActivityRequest({ username: "Soma", filter: "likes-given" }).data
        .filter,
      "1"
    );
  });

  it("builds topic-list requests for bytes and read history", () => {
    assert.deepEqual(
      ownedActivityRequest({ username: "Soma", filter: "topics" }),
      {
        url: "/topics/created-by/Soma.json",
        data: null,
      }
    );
    assert.deepEqual(
      ownedActivityRequest({ username: "Soma", filter: "read" }, { page: 2 }),
      {
        url: "/read.json",
        data: { offset: 60 },
      }
    );
  });

  it("normalizes user actions to activity items", () => {
    assert.deepEqual(
      normalizeUserAction({
        action_type: 5,
        topic_id: 42,
        post_number: 3,
        slug: "hello",
        title: "Hello",
        username: "Soma",
        created_at: "2026-06-21T10:00:00Z",
      }),
      {
        id: "action-5-42-3-2026-06-21T10:00:00Z",
        type: "reply",
        eyebrow: "Reply",
        title: "Hello",
        excerpt: "Soma replied in this conversation.",
        href: "/t/hello/42/3",
        createdAt: "2026-06-21T10:00:00Z",
        actor: "Soma",
      }
    );
  });

  it("describes created Bytes without generic profile filler", () => {
    assert.equal(
      normalizeUserAction({
        action_type: 4,
        topic_id: 42,
        post_number: 1,
        slug: "hello",
        title: "Hello",
        target_username: "Soma",
        username: "Soma",
        created_at: "2026-06-21T10:00:00Z",
      }).excerpt,
      "Soma started this Byte."
    );
  });

  it("normalizes payloads and pagination", () => {
    const actions = Array.from({ length: 30 }, (_, i) => ({
      action_type: 4,
      topic_id: i + 1,
      post_number: 1,
      title: `Byte ${i + 1}`,
    }));

    assert.equal(
      normalizeOwnedActivityPayload(
        { user_actions: actions },
        { filter: "all" },
        { page: 1 }
      ).nextPage,
      2
    );

    assert.deepEqual(
      normalizeOwnedActivityPayload(
        {
          topic_list: {
            more_topics_url: "/topics/created-by/Soma.json?page=2",
            topics: [{ id: 1, title: "Topic", slug: "topic" }],
          },
        },
        { filter: "topics" }
      ).loadMoreUrl,
      "/topics/created-by/Soma.json?page=2"
    );
  });
});
