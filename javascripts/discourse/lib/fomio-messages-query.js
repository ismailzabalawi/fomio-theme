import { ajax } from "discourse/lib/ajax";
import { conversationListUrl } from "./fomio-messages-routes";

export async function fetchConversationList(
  username,
  filter = "inbox",
  page = 0,
  options = {}
) {
  const url = conversationListUrl({
    username,
    filter,
    page,
    inbox: options.inbox,
    groupName: options.groupName,
    tagName: options.tagName,
  });

  if (!url) {
    return [];
  }

  try {
    const response = await ajax(url);

    return transformDiscoursePayload(response, { currentUsername: username });
  } catch (error) {
    console.error("[Fomio] Messages: Failed to fetch conversation list", error);
    return [];
  }
}

export function transformDiscoursePayload(rawPayload, options = {}) {
  if (!rawPayload?.topic_list?.topics) {
    return [];
  }

  const usersMap = new Map();
  (rawPayload.users || []).forEach((u) => usersMap.set(u.id, u));

  return rawPayload.topic_list.topics.map((topic) => {
    const participant = conversationParticipant(topic, usersMap, options);
    const participantGroups = topic.participant_groups || [];
    const isGroup = participantGroups.length > 0;

    return {
      id: topic.id,
      slug: topic.slug,
      title: topic.fancy_title || topic.title,
      isUnread: topic.unseen || topic.unread_posts > 0,
      unreadCount: topic.unread_posts || topic.new_posts || 0,
      lastPostedAt: topic.last_posted_at,
      excerpt: cleanExcerpt(topic.excerpt),
      participant,
      isGroup,
      groupNames: participantGroups.map((group) => group.name).filter(Boolean),
      lastPosterUsername:
        topic.last_poster?.username || topic.last_poster_username || null,
      replyCount: topic.reply_count,
      postCount: topic.posts_count,
    };
  });
}

function cleanExcerpt(excerpt) {
  if (!excerpt) {
    return "No preview yet.";
  }

  return excerpt.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

function conversationParticipant(topic, usersMap, options) {
  const currentUsername = options.currentUsername?.toLowerCase();
  const participants = [...(topic.participants || []), ...(topic.posters || [])];
  const targetPoster =
    participants.find((participant) => {
      const user = usersMap.get(participant.user_id);
      return user?.username?.toLowerCase() !== currentUsername;
    }) || participants[0];

  const targetUser = targetPoster ? usersMap.get(targetPoster.user_id) : null;
  const lastPosterUser = topic.last_poster
    ? usersMap.get(topic.last_poster.id) || topic.last_poster
    : null;

  return {
    username:
      targetUser?.username ||
      lastPosterUser?.username ||
      topic.last_poster_username ||
      "Conversation",
    name: targetUser?.name || lastPosterUser?.name || null,
    avatarTemplate:
      targetUser?.avatar_template || lastPosterUser?.avatar_template || null,
  };
}
