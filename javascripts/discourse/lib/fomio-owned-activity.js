const ACTIVITY_PATH_RE =
  /^\/u\/([^/]+)\/activity(?:\/(topics|replies|read|likes-given))?\/?$/i;
const MY_ACTIVITY_PATH_RE =
  /^\/my\/activity(?:\/(topics|replies|read|likes-given))?\/?$/i;

export const OWNED_ACTIVITY_LIMIT = 30;

const ACTIVITY_CONFIG = {
  all: {
    endpoint: "user-actions",
    filter: "4,5",
  },
  topics: {
    endpoint: "topics",
  },
  replies: {
    endpoint: "user-actions",
    filter: "5",
  },
  read: {
    endpoint: "read",
  },
  "likes-given": {
    endpoint: "user-actions",
    filter: "1",
  },
};

const USER_ACTION_LABELS = {
  1: "Liked",
  4: "Byte",
  5: "Reply",
};

export function parseOwnedActivityRoute(currentUrl, currentUser = null) {
  const parsed = parseUrl(currentUrl);
  const path = parsed.pathname.replace(/\/+$/, "") || "/";
  const userMatch = path.match(ACTIVITY_PATH_RE);
  const myMatch = path.match(MY_ACTIVITY_PATH_RE);

  if (!userMatch && !myMatch) {
    return { isActivity: false, username: null, filter: null, isSelf: false };
  }

  const username = userMatch?.[1]
    ? decodeURIComponent(userMatch[1])
    : currentUser?.username ?? null;

  if (!username) {
    return { isActivity: false, username: null, filter: null, isSelf: false };
  }

  const segment = userMatch?.[2] ?? myMatch?.[1] ?? "all";
  const filter = normalizeActivityFilter(segment);

  if (!filter) {
    return { isActivity: false, username, filter: null, isSelf: false };
  }

  const isSelf =
    Boolean(myMatch) ||
    Boolean(
      userMatch?.[1] &&
        currentUser?.username &&
        username.toLowerCase() === String(currentUser.username).toLowerCase()
    );

  // The read-history endpoint reflects the signed-in user, not the viewed
  // profile — never own it on someone else's activity page.
  if (!isSelf && filter === "read") {
    return { isActivity: false, username, filter, isSelf: false };
  }

  return { isActivity: true, username, filter, isSelf };
}

export function normalizeActivityFilter(filter) {
  return ACTIVITY_CONFIG[filter] ? filter : null;
}

export function ownedActivityRequest(routeState, options = {}) {
  if (options.loadMoreUrl) {
    return { url: options.loadMoreUrl, data: null };
  }

  const filter = normalizeActivityFilter(routeState?.filter) ?? "all";
  const username = routeState?.username;
  const page = options.page ?? 0;
  const offset = page * (options.limit ?? OWNED_ACTIVITY_LIMIT);
  const config = ACTIVITY_CONFIG[filter];

  if (!username || !config) {
    return null;
  }

  if (config.endpoint === "user-actions") {
    return {
      url: "/user_actions.json",
      data: {
        offset,
        limit: options.limit ?? OWNED_ACTIVITY_LIMIT,
        username,
        filter: config.filter,
      },
    };
  }

  if (config.endpoint === "topics") {
    return {
      url: `/topics/created-by/${encodeURIComponent(username)}.json`,
      data: page > 0 ? { page } : null,
    };
  }

  if (config.endpoint === "read") {
    return {
      url: "/read.json",
      data: page > 0 ? { offset } : null,
    };
  }

  return null;
}

export function normalizeOwnedActivityPayload(payload = {}, routeState = {}, options = {}) {
  const filter = normalizeActivityFilter(routeState.filter) ?? "all";
  const page = options.page ?? 0;

  if (Array.isArray(payload.user_actions)) {
    return {
      items: payload.user_actions.map((action) =>
        normalizeUserAction(action, filter)
      ),
      nextPage:
        payload.user_actions.length >= (options.limit ?? OWNED_ACTIVITY_LIMIT)
          ? page + 1
          : null,
      loadMoreUrl: null,
    };
  }

  const topicList = payload.topic_list ?? {};
  if (Array.isArray(topicList.topics)) {
    return {
      items: topicList.topics.map((topic) => normalizeTopic(topic, filter)),
      nextPage: topicList.more_topics_url ? null : null,
      loadMoreUrl: topicList.more_topics_url || null,
    };
  }

  return { items: [], nextPage: null, loadMoreUrl: null };
}

export function normalizeUserAction(action = {}, filter = "all") {
  const postNumber =
    Number(action.post_number) || Number(action.reply_to_post_number) || 1;
  const href = activityPostPath({
    slug: action.slug,
    topicId: action.topic_id,
    postNumber,
  });

  return {
    id: `action-${action.action_type}-${action.topic_id}-${postNumber}-${action.created_at}`,
    type: filter === "likes-given" ? "like" : actionTypeKey(action.action_type),
    eyebrow: USER_ACTION_LABELS[action.action_type] ?? "Activity",
    title: action.title || "Untitled Byte",
    excerpt: actionDescription(action),
    href,
    createdAt: action.created_at,
    actor: action.acting_username || action.username || null,
  };
}

export function normalizeTopic(topic = {}, filter = "topics") {
  return {
    id: `topic-${topic.id}`,
    type: filter === "read" ? "read" : "byte",
    eyebrow: filter === "read" ? "Read" : "Byte",
    title: topic.fancy_title || topic.title || "Untitled Byte",
    excerpt: cleanExcerpt(topic.excerpt),
    href: activityPostPath({
      slug: topic.slug,
      topicId: topic.id,
      postNumber: topic.last_read_post_number || topic.highest_post_number || 1,
    }),
    createdAt: topic.last_posted_at || topic.bumped_at || topic.created_at,
    actor: topic.last_poster_username || null,
  };
}

function actionTypeKey(actionType) {
  if (actionType === 1) {
    return "like";
  }
  if (actionType === 5) {
    return "reply";
  }
  return "byte";
}

function actionDescription(action) {
  const actor = action.acting_username || action.username;

  if (action.action_type === 4 && actor) {
    return `${actor} started this Byte.`;
  }

  if (action.action_type === 1 && actor) {
    return `${actor} liked this Byte.`;
  }

  if (action.action_type === 5 && actor) {
    return `${actor} replied in this conversation.`;
  }

  return "";
}

function cleanExcerpt(excerpt) {
  if (!excerpt) {
    return "";
  }

  return String(excerpt).replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

function activityPostPath({ slug, topicId, postNumber }) {
  if (!topicId) {
    return "#";
  }

  const safeSlug = slug || "topic";
  const suffix = postNumber && Number(postNumber) > 1 ? `/${postNumber}` : "";
  return `/t/${safeSlug}/${topicId}${suffix}`;
}

function parseUrl(currentUrl) {
  try {
    return new URL(currentUrl || "/", "https://fomio.local");
  } catch {
    return new URL("/", "https://fomio.local");
  }
}
