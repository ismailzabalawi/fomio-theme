import Component from "@glimmer/component";
import { service } from "@ember/service";
import UserLink from "discourse/components/user-link";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioIdentity from "../../components/shared/fomio-identity";
import { preservePreviewTheme, userMessagesPath } from "../../lib/fomio-messages-routes";

export default class FomioTopicReadingMeta extends Component {
  @service currentUser;

  get topic() {
    return this.args.outletArgs.model;
  }

  get isPrivateMessage() {
    return this.topic?.archetype === "private_message";
  }

  get author() {
    return this.topic?.details?.created_by;
  }

  get category() {
    return this.topic?.category;
  }

  get hub() {
    return this.category?.parentCategory ?? null;
  }

  get deck() {
    const excerpt = this.topic?.escapedExcerpt ?? this.topic?.excerpt ?? "";

    return excerpt
      .replace(/<[^>]*>/g, " ")
      .replace(/&hellip;/g, "...")
      .replace(/&#39;/g, "'")
      .replace(/&quot;/g, '"')
      .replace(/&amp;/g, "&")
      .replace(/&nbsp;/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  get readTimeMinutes() {
    const words = this.topic?.word_count ?? this.topic?.wordCount ?? 0;
    return Math.max(1, Math.ceil(words / 200));
  }

  get allowedUsers() {
    return this.topic?.details?.allowed_users || [];
  }

  get allowedGroups() {
    return this.topic?.details?.allowed_groups || [];
  }

  get participantCount() {
    return this.topic?.participant_count || this.allowedUsers.length || 1;
  }

  get otherParticipants() {
    const currentUserId = this.currentUser?.id;
    const currentUsername = this.currentUser?.username?.toLowerCase();

    return this.allowedUsers.filter((user) => {
      return (
        user.id !== currentUserId &&
        user.username?.toLowerCase() !== currentUsername
      );
    });
  }

  get groupName() {
    return this.allowedGroups[0]?.full_name || this.allowedGroups[0]?.name || null;
  }

  get directParticipant() {
    return this.otherParticipants[0] || this.author || null;
  }

  get conversationTitle() {
    if (this.groupName) {
      return this.groupName;
    }

    const participant = this.directParticipant;
    return participant?.name || participant?.username || this.topic?.title;
  }

  get conversationSubtitle() {
    if (this.groupName || this.participantCount > 2) {
      return i18n(themePrefix("messages_inbox.participants_count"), {
        count: this.participantCount,
      });
    }

    return i18n(themePrefix("messages_inbox.personal_message"));
  }

  get messagesPath() {
    return preservePreviewTheme(
      userMessagesPath(this.currentUser?.username),
      window.location.search
    );
  }

  get backToMessagesLabel() {
    return i18n(themePrefix("messages_inbox.back_to_messages"));
  }

  <template>
    {{#if this.isPrivateMessage}}
      <div class="fomio-topic-header fomio-topic-header--pm">
        <a href={{this.messagesPath}} class="fomio-conversation-header__back">
          {{this.backToMessagesLabel}}
        </a>

        {{#if this.groupName}}
          <div class="fomio-conversation-header__identity fomio-conversation-header__identity--group">
            <span class="fomio-conversation-header__title">{{this.conversationTitle}}</span>
            <span class="fomio-conversation-header__subtitle">{{this.conversationSubtitle}}</span>
          </div>
        {{else if this.directParticipant}}
          <UserLink @user={{this.directParticipant}} class="fomio-conversation-header__identity">
            <FomioIdentity
              @user={{this.directParticipant}}
              @name={{this.conversationTitle}}
              @showHandle={{false}}
              @avatarSize="sm"
            />
            <span class="fomio-conversation-header__subtitle">{{this.conversationSubtitle}}</span>
          </UserLink>
        {{/if}}
      </div>
    {{else}}
      <div class="fomio-topic-header">
        {{#if this.category}}
          <div class="fomio-topic-header__crumbs">
            {{#if this.hub}}
              <a href={{this.hub.url}} class="fomio-topic-header__crumb fomio-topic-header__crumb--hub">
                {{this.hub.name}}
              </a>
              <span class="fomio-topic-header__crumb-sep" aria-hidden="true">/</span>
            {{/if}}
            <a href={{this.category.url}} class="fomio-topic-header__crumb">
              {{this.category.name}}
            </a>
          </div>
        {{/if}}

        {{#if this.deck}}
          <p class="fomio-topic-header__deck">
            {{this.deck}}
          </p>
        {{/if}}

        {{#if this.author}}
          <div class="fomio-topic-reading-meta">
            <UserLink @user={{this.author}} class="fomio-topic-reading-meta__author">
              <FomioIdentity
                @user={{this.author}}
                @name={{this.author.username}}
                @showHandle={{false}}
                @avatarSize="sm"
              />
            </UserLink>

            <span class="fomio-topic-reading-meta__date">
              {{formatDate this.topic.created_at format="medium" noTitle="true"}}
            </span>

            <span class="fomio-topic-reading-meta__read-time">
              {{this.readTimeMinutes}} min read
            </span>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
