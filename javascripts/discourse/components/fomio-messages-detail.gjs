import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";
import { ajax } from "discourse/lib/ajax";
import DiscourseURL from "discourse/lib/url";
import icon from "discourse/helpers/d-icon";
import { themePrefix } from "virtual:theme";
import {
  setMessagesState,
  subscribeMessagesState,
} from "../lib/fomio-messages-state";
import {
  groupMessagesPath,
  preservePreviewTheme,
  userMessagesPath,
} from "../lib/fomio-messages-routes";

export default class FomioMessagesDetail extends Component {
  @service currentUser;

  @tracked selectedTopicId = null;
  @tracked topic = null;
  @tracked isLoading = false;
  @tracked error = null;
  @tracked activeFilter = "inbox";
  @tracked activeGroupName = null;
  @tracked headerSearchOpen = false;
  @tracked infoOpen = false;
  @tracked searchQuery = "";

  #unsubscribeState = null;

  constructor(owner, args) {
    super(owner, args);

    this.#unsubscribeState = subscribeMessagesState((state) => {
      this.activeFilter = state.filter;
      this.activeGroupName = state.activeGroupName;

      if (this.selectedTopicId !== state.selectedTopicId) {
        this.selectedTopicId = state.selectedTopicId;
        this.headerSearchOpen = false;
        this.infoOpen = false;
        this.searchQuery = "";

        if (this.selectedTopicId) {
          this.loadThread(this.selectedTopicId);
        } else {
          this.topic = null;
          this.error = null;
        }
      }
    });
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#unsubscribeState?.();
  }

  getSafeContent(content) {
    return htmlSafe(content);
  }

  stripHtml(html) {
    if (!html) {
      return "";
    }

    return html.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  }

  formatPostTime(dateString) {
    if (!dateString) {
      return "";
    }

    return new Date(dateString).toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
    });
  }

  formatPostTimeAbsolute(dateString) {
    if (!dateString) {
      return "";
    }

    const date = new Date(dateString);
    const now = new Date();

    return date.toLocaleString("en-US", {
      month: "short",
      day: "numeric",
      year: date.getFullYear() !== now.getFullYear() ? "numeric" : undefined,
      hour: "numeric",
      minute: "2-digit",
    });
  }

  formatDayLabel(dateString) {
    if (!dateString) {
      return "";
    }

    const date = new Date(dateString);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const target = new Date(
      date.getFullYear(),
      date.getMonth(),
      date.getDate()
    );

    if (target.getTime() === today.getTime()) {
      return i18n(themePrefix("messages_inbox.day.today"));
    }

    if (target.getTime() === yesterday.getTime()) {
      return i18n(themePrefix("messages_inbox.day.yesterday"));
    }

    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    });
  }

  isCurrentUserPost(post) {
    return (
      post.username?.toLowerCase() === this.currentUser?.username?.toLowerCase()
    );
  }

  get participants() {
    return this.topic?.details?.participants || [];
  }

  get otherParticipants() {
    return this.participants.filter(
      (participant) =>
        participant.username?.toLowerCase() !==
        this.currentUser?.username?.toLowerCase()
    );
  }

  get isGroupConversation() {
    return Boolean(this.topic?.details?.allowed_groups?.length);
  }

  get conversationTitle() {
    const allowedGroups = this.topic?.details?.allowed_groups || [];

    if (allowedGroups.length) {
      return allowedGroups[0].name;
    }

    const firstParticipant = this.otherParticipants[0];
    return (
      firstParticipant?.name ||
      firstParticipant?.username ||
      i18n(themePrefix("messages_inbox.private_conversation_kicker"))
    );
  }

  get conversationSubtitle() {
    if (this.isGroupConversation) {
      const count = this.participants.length;
      return i18n(themePrefix("messages_inbox.participants_count"), { count });
    }

    const lastPostedAt =
      this.topic?.last_posted_at || this.topic?.post_stream?.posts?.at(-1)?.created_at;

    if (!lastPostedAt) {
      return null;
    }

    const hoursAgo = (Date.now() - new Date(lastPostedAt).getTime()) / 3600000;

    if (hoursAgo < 12) {
      return i18n(themePrefix("messages_inbox.active_recently"));
    }

    return this.formatDayLabel(lastPostedAt);
  }

  get participantSummary() {
    const names = this.participants
      .map((participant) => participant.name || participant.username)
      .filter(Boolean);

    if (!names.length) {
      return null;
    }

    return names.join(", ");
  }

  get visiblePosts() {
    const posts = this.topic?.post_stream?.posts || [];
    const query = this.searchQuery.trim().toLowerCase();

    if (!query) {
      return posts;
    }

    return posts.filter((post) => {
      const haystack = [
        post.username,
        post.name,
        this.stripHtml(post.cooked),
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      return haystack.includes(query);
    });
  }

  get groupedPosts() {
    const groups = [];

    for (const post of this.visiblePosts) {
      const row = {
        ...post,
        isCurrentUser: this.isCurrentUserPost(post),
        meta: this.postMeta(post),
        absoluteTime: this.formatPostTimeAbsolute(post.created_at),
        safeCooked: this.getSafeContent(post.cooked),
      };
      const label = this.formatDayLabel(post.created_at);
      const lastGroup = groups.at(-1);

      if (!lastGroup || lastGroup.label !== label) {
        groups.push({ label, posts: [row] });
      } else {
        lastGroup.posts.push(row);
      }
    }

    return groups;
  }

  get loadingThreadMessage() {
    return i18n(themePrefix("messages_inbox.loading_thread"));
  }

  get backToMessagesLabel() {
    return i18n(themePrefix("messages_inbox.back_to_messages"));
  }

  get openReplyLabel() {
    return i18n(themePrefix("messages_inbox.open_reply"));
  }

  get replyPlaceholderLabel() {
    return i18n(themePrefix("messages_inbox.reply_placeholder"));
  }

  get emptyDetailMessage() {
    return i18n(themePrefix("messages_inbox.empty.detail"));
  }

  get searchConversationLabel() {
    return i18n(themePrefix("messages_inbox.search_conversation"));
  }

  get infoLabel() {
    return i18n(themePrefix("messages_inbox.info"));
  }

  get searchPlaceholder() {
    return i18n(themePrefix("messages_inbox.search_messages_placeholder"));
  }

  postMeta(post) {
    const speaker = this.isCurrentUserPost(post)
      ? i18n(themePrefix("messages_inbox.you"))
      : post.name || post.username;

    return `${speaker} \u00b7 ${this.formatPostTime(post.created_at)}`;
  }

  @action
  openReplyComposer() {
    if (!this.selectedTopicId || !this.topic) {
      return;
    }

    window.location.href = `/t/${this.topic.slug}/${this.selectedTopicId}`;
  }

  @action
  closeConversation() {
    setMessagesState({ selectedTopicId: null });

    const destination =
      this.activeFilter === "groups" && this.activeGroupName
        ? groupMessagesPath(
            this.currentUser?.username,
            this.activeGroupName,
            this.activeGroupFilter
          )
        : userMessagesPath(this.currentUser?.username, this.activeFilter);

    DiscourseURL.routeTo(
      preservePreviewTheme(destination, window.location.search)
    );
  }

  @action
  toggleSearch() {
    this.headerSearchOpen = !this.headerSearchOpen;

    if (!this.headerSearchOpen) {
      this.searchQuery = "";
    }
  }

  @action
  toggleInfo() {
    this.infoOpen = !this.infoOpen;
  }

  @action
  updateSearch(event) {
    this.searchQuery = event.target.value;
  }

  @action
  async loadThread(topicId) {
    this.isLoading = true;
    this.error = null;

    try {
      this.topic = await ajax(`/t/${topicId}.json`);
    } catch (error) {
      console.error("Error loading thread:", error);
      this.error = i18n(themePrefix("messages_inbox.error_thread"));
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    {{#if this.selectedTopicId}}
      <div class="fomio-messages-detail-container">
        {{#if this.isLoading}}
          <div class="fomio-detail-loading">
            {{this.loadingThreadMessage}}
          </div>
        {{else if this.error}}
          <div class="fomio-detail-error">{{this.error}}</div>
        {{else if this.topic}}
          <div class="fomio-messages-thread">
            <div class="fomio-messages-thread-header">
              <div class="fomio-messages-thread-topbar">
                <button
                  type="button"
                  class="fomio-messages-back-button"
                  {{on "click" this.closeConversation}}
                >
                  {{this.backToMessagesLabel}}
                </button>

                <div class="fomio-messages-thread-actions">
                  <button
                    type="button"
                    class="fomio-messages-thread-action"
                    aria-label={{this.searchConversationLabel}}
                    {{on "click" this.toggleSearch}}
                  >
                    {{icon "search"}}
                  </button>
                  <button
                    type="button"
                    class="fomio-messages-thread-action"
                    aria-label={{this.infoLabel}}
                    {{on "click" this.toggleInfo}}
                  >
                    {{icon "info-circle"}}
                  </button>
                </div>
              </div>

              <h2 class="fomio-messages-thread-title">
                {{this.conversationTitle}}
              </h2>

              {{#if this.conversationSubtitle}}
                <p class="fomio-messages-thread-summary">
                  {{this.conversationSubtitle}}
                </p>
              {{/if}}

              {{#if this.headerSearchOpen}}
                <label class="fomio-messages-thread-search">
                  <span class="sr-only">{{this.searchConversationLabel}}</span>
                  <input
                    type="search"
                    placeholder={{this.searchPlaceholder}}
                    value={{this.searchQuery}}
                    {{on "input" this.updateSearch}}
                  />
                </label>
              {{/if}}

              {{#if this.infoOpen}}
                <div class="fomio-messages-thread-info">
                  {{#if this.participantSummary}}
                    <p>{{this.participantSummary}}</p>
                  {{/if}}
                </div>
              {{/if}}
            </div>

            <div class="fomio-messages-list">
              {{#each this.groupedPosts as |group|}}
                <div class="fomio-message-day-group">
                  <div class="fomio-message-day-separator">
                    <span>{{group.label}}</span>
                  </div>

                  {{#each group.posts as |post|}}
                    <div class="fomio-message-row {{if post.isCurrentUser 'fomio-message-row--mine'}}">
                      <div
                        class="fomio-message-header"
                        title={{post.absoluteTime}}
                      >
                        {{post.meta}}
                      </div>

                      <div class="fomio-message-body">
                        {{{post.safeCooked}}}
                      </div>
                    </div>
                  {{/each}}
                </div>
              {{/each}}
            </div>

            <div class="fomio-messages-composer-footer">
              <button
                type="button"
                class="fomio-reply-launcher"
                {{on "click" this.openReplyComposer}}
              >
                <span class="fomio-reply-launcher__plus">+</span>
                <span class="fomio-reply-launcher__label">
                  {{this.replyPlaceholderLabel}}
                </span>
              </button>
            </div>
          </div>
        {{/if}}
      </div>
    {{else}}
      <div class="fomio-messages-empty-state">
        {{this.emptyDetailMessage}}
      </div>
    {{/if}}
  </template>
}
