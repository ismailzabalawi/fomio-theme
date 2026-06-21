import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Fomio Conversation Card
 *
 * Minimal, reading-focused card for a single PM conversation.
 * Shows: avatar, username, subject, snippet, timestamp, unread flag.
 *
 * Usage:
 *   <FomioConversationCard
 *     @conversation={{conversation}}
 *     @isActive={{false}}
 *     @onClick={{fn selectConversation conversation.id}}
 *   />
 *
 * Conversation shape:
 *   {
 *     id: number,
 *     title: string,
 *     isUnread: boolean,
 *     lastPostedAt: ISO8601,
 *     excerpt: string,
 *     participant: { username: string, avatarTemplate: string },
 *     isGroup: boolean
 *   }
 */

export default class FomioConversationCard extends Component {
  get participantLabel() {
    return (
      this.args.conversation.participant.name ||
      this.args.conversation.participant.username
    );
  }

  get participantMeta() {
    if (this.args.conversation.unreadCount > 0) {
      return i18n(themePrefix("messages_inbox.unread_count"), {
        count: this.args.conversation.unreadCount,
      });
    }

    return null;
  }

  get previewLine() {
    const excerpt = this.args.conversation.excerpt;

    if (this.args.conversation.isGroup && this.args.conversation.lastPosterUsername) {
      return `${this.args.conversation.lastPosterUsername}: ${excerpt}`;
    }

    return excerpt;
  }

  get contextLine() {
    if (this.args.conversation.isGroup && this.args.conversation.groupNames?.length) {
      return this.args.conversation.groupNames[0];
    }

    const title = this.args.conversation.title?.trim();
    const excerpt = this.args.conversation.excerpt?.trim();

    if (title && excerpt && title !== excerpt) {
      return title;
    }

    return null;
  }

  get ariaLabel() {
    return i18n(themePrefix("messages_inbox.open_conversation_aria"), {
      title: this.args.conversation.title,
      participant: this.participantLabel,
    });
  }

  get avatarSrc() {
    const template = this.args.conversation.participant.avatarTemplate;

    if (!template) {
      return null;
    }

    return template.replace("{size}", "40");
  }

  get formattedTime() {
    if (!this.args.conversation.lastPostedAt) {
      return "";
    }

    const date = new Date(this.args.conversation.lastPostedAt);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return "now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;

    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    });
  }

  @action
  selectConversation(event) {
    if (!this.args.onSelect) {
      return;
    }

    event.preventDefault();
    this.args.onSelect(this.args.conversation);
  }

  <template>
    <a
      href={{@href}}
      class="fomio-conversation-card
        {{if @isActive 'fomio-conversation-card--active'}}
        {{if @conversation.isUnread 'fomio-conversation-card--unread'}}"
      aria-current={{if @isActive "true"}}
      aria-label={{this.ariaLabel}}
      {{on "click" this.selectConversation}}
    >
      <div class="fomio-conversation-card__avatar-wrapper">
        {{#if @conversation.isGroup}}
          <div class="fomio-conversation-card__avatar fomio-conversation-card__avatar--group">
            {{icon "users"}}
          </div>
        {{else}}
          <img
            src={{this.avatarSrc}}
            alt=""
            width="40"
            height="40"
            class="avatar"
          />
        {{/if}}
      </div>

      <div class="fomio-conversation-card__content">
        <div class="fomio-conversation-card__header">
          <div class="fomio-conversation-card__identity">
            <span class="fomio-conversation-card__username">
              {{this.participantLabel}}
            </span>
            {{#if this.participantMeta}}
              <span class="fomio-conversation-card__meta">
                {{this.participantMeta}}
              </span>
            {{/if}}
          </div>
          <span class="fomio-conversation-card__timestamp">
            {{this.formattedTime}}
          </span>
        </div>

        {{#if this.contextLine}}
          <p class="fomio-conversation-card__context">
            {{this.contextLine}}
          </p>
        {{/if}}

        <p class="fomio-conversation-card__excerpt">
          {{this.previewLine}}
        </p>
      </div>

      {{#if @conversation.isUnread}}
        <div class="fomio-conversation-card__unread-indicator"></div>
      {{/if}}
    </a>
  </template>
}
