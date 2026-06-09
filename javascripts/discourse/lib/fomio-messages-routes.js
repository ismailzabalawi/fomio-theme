export const FOMIO_MESSAGE_FILTERS = ["inbox", "unread", "sent", "groups"];

export const USER_MESSAGE_ENDPOINTS = {
  inbox: "private-messages",
  sent: "private-messages-sent",
  unread: "private-messages-unread",
  archive: "private-messages-archive",
  new: "private-messages-new",
};

export const GROUP_MESSAGE_ENDPOINTS = {
  inbox: "",
  unread: "unread",
  archive: "archive",
  new: "new",
};

export function normalizeMessagePath(path) {
  return path?.split("?")[0]?.replace(/\/+$/, "") || "/";
}

export function preservePreviewTheme(basePath, currentSearch = "") {
  const params = new URLSearchParams(
    String(currentSearch || "").replace(/^\?/, "")
  );
  const previewThemeId = params.get("preview_theme_id");

  if (!previewThemeId) {
    return basePath;
  }

  const nextParams = new URLSearchParams();
  nextParams.set("preview_theme_id", previewThemeId);

  return `${basePath}?${nextParams.toString()}`;
}

export function fomioFilterFromDiscourseFilter(filter) {
  if (filter === "latest" || filter === "inbox" || !filter) {
    return "inbox";
  }

  if (filter === "archive" || filter === "new") {
    return "inbox";
  }

  if (FOMIO_MESSAGE_FILTERS.includes(filter)) {
    return filter;
  }

  return "inbox";
}

export function parseFomioMessagesPath(path) {
  const normalizedPath = normalizeMessagePath(path);
  const normalizedLowerPath = normalizedPath.toLowerCase();
  const groupMatch =
    /^\/(?:u\/[^/]+|my)\/messages\/group\/([^/]+)(?:\/([^/]+))?(?:\/|$)/.exec(
      normalizedPath
    );

  if (groupMatch) {
    return {
      isMessagesPath: true,
      filter: "groups",
      inbox: "group",
      groupName: decodeURIComponent(groupMatch[1]),
      groupFilter: fomioFilterFromDiscourseFilter(groupMatch[2]?.toLowerCase()),
      tagName: null,
    };
  }

  const tagsMatch =
    /^\/(?:u\/[^/]+|my)\/messages\/tags\/([^/]+)(?:\/|$)/.exec(
      normalizedPath
    );

  if (tagsMatch) {
    return {
      isMessagesPath: true,
      filter: "inbox",
      inbox: "tag",
      groupName: null,
      tagName: decodeURIComponent(tagsMatch[1]),
    };
  }

  const userMatch = /^\/(?:u\/[^/]+|my)\/messages(?:\/([^/]+))?(?:\/|$)/.exec(
    normalizedLowerPath
  );

  if (userMatch) {
    return {
      isMessagesPath: true,
      filter: fomioFilterFromDiscourseFilter(userMatch[1]),
      inbox: "user",
      groupName: null,
      tagName: null,
    };
  }

  return {
    isMessagesPath: false,
    filter: null,
    inbox: null,
    groupName: null,
    tagName: null,
  };
}

export function userMessagesPath(username, filter = "inbox") {
  const root = username ? `/u/${username}/messages` : "/my/messages";

  if (filter === "inbox" || filter === "groups") {
    return root;
  }

  return `${root}/${filter}`;
}

export function groupMessagesPath(username, groupName, filter = "inbox") {
  const root = username ? `/u/${username}/messages` : "/my/messages";
  const groupPath = `${root}/group/${encodeURIComponent(groupName)}`;

  if (filter === "inbox" || filter === "groups") {
    return groupPath;
  }

  return `${groupPath}/${filter}`;
}

export function conversationListUrl({
  username,
  filter = "inbox",
  page = 0,
  inbox = "user",
  groupName = null,
  tagName = null,
}) {
  if (!username) {
    return null;
  }

  if (inbox === "tag" && tagName) {
    return `/topics/private-messages-tags/${username}/${encodeURIComponent(
      tagName
    )}.json?page=${page}`;
  }

  if (inbox === "group" && groupName) {
    const groupFilter =
      GROUP_MESSAGE_ENDPOINTS[filter] ?? GROUP_MESSAGE_ENDPOINTS.inbox;
    const suffix = groupFilter ? `/${groupFilter}` : "";
    return `/topics/private-messages-group/${username}/${encodeURIComponent(
      groupName
    )}${suffix}.json?page=${page}`;
  }

  const endpoint = USER_MESSAGE_ENDPOINTS[filter] || USER_MESSAGE_ENDPOINTS.inbox;
  return `/topics/${endpoint}/${username}.json?page=${page}`;
}
