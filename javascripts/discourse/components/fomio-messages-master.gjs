import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import DiscourseURL from "discourse/lib/url";
import { themePrefix } from "virtual:theme";
import { fetchConversationList } from "../lib/fomio-messages-query";
import {
  groupMessagesPath,
  preservePreviewTheme,
  userMessagesPath,
} from "../lib/fomio-messages-routes";
import {
  subscribeMessagesState,
  setMessagesState,
} from "../lib/fomio-messages-state";
import FomioConversationCard from "./fomio-conversation-card";

export default class FomioMessagesMaster extends Component {
  @service currentUser;

  @tracked conversations = [];
  @tracked isLoading = true;
  @tracked activeFilter = "inbox";
  @tracked activeGroupName = null;
  @tracked activeGroupFilter = "inbox";
  @tracked searchQuery = "";

  #unsubscribeMessages = null;

  constructor(owner, args) {
    super(owner, args);

    this.#unsubscribeMessages = subscribeMessagesState((state) => {
      if (
        this.activeFilter !== state.filter ||
        this.activeGroupName !== state.activeGroupName ||
        this.activeGroupFilter !== state.activeGroupFilter
      ) {
        this.activeFilter = state.filter;
        this.activeGroupName = state.activeGroupName;
        this.activeGroupFilter = state.activeGroupFilter;
        this.loadConversations(
          state.filter,
          state.activeGroupName,
          state.activeGroupFilter
        );
      }

      this.searchQuery = state.searchQuery;
    });

    this.loadConversations(
      this.activeFilter,
      this.activeGroupName,
      this.activeGroupFilter
    );
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#unsubscribeMessages?.();
  }

  get filters() {
    return [
      { key: "inbox", label: i18n(themePrefix("messages_inbox.filters.all")) },
      { key: "unread", label: i18n(themePrefix("messages_inbox.filters.unread")) },
      { key: "groups", label: i18n(themePrefix("messages_inbox.filters.groups")) },
    ];
  }

  get groupInboxes() {
    const groups = this.currentUser?.groupsWithMessages;

    if (!groups) {
      return [];
    }

    return groups.toArray?.() || Array.from(groups);
  }

  get titleLabel() {
    return i18n(themePrefix("messages_inbox.title"));
  }

  get filtersAriaLabel() {
    return i18n(themePrefix("messages_inbox.filters_aria"));
  }

  get searchLabel() {
    return i18n(themePrefix("messages_inbox.search_label"));
  }

  get searchPlaceholder() {
    return i18n(themePrefix("messages_inbox.search_placeholder"));
  }

  get groupsHeading() {
    return i18n(themePrefix("messages_inbox.groups_heading"));
  }

  get groupsDescription() {
    return i18n(themePrefix("messages_inbox.groups_description"));
  }

  get groupCardMeta() {
    return i18n(themePrefix("messages_inbox.group_card_meta"));
  }

  get groupsEmptyMessage() {
    return i18n(themePrefix("messages_inbox.empty.groups"));
  }

  get loadingListMessage() {
    return i18n(themePrefix("messages_inbox.loading_list"));
  }

  get newMessageLabel() {
    return i18n(themePrefix("messages_inbox.new_message"));
  }

  get newMessageAriaLabel() {
    return i18n(themePrefix("messages_inbox.new_message_aria"));
  }

  get emptyStateMessage() {
    return i18n(themePrefix(`messages_inbox.empty.${this.activeFilter}`));
  }

  get emptyStateBodyMessage() {
    return i18n(themePrefix("messages_inbox.empty.body"));
  }

  get conversationSections() {
    if (this.activeFilter === "groups") {
      return [];
    }

    const visible = this.sortConversations(this.visibleConversations);

    if (this.activeFilter === "unread") {
      return [
        {
          key: "unread",
          title: null,
          conversations: visible,
        },
      ];
    }

    const unread = visible.filter((conversation) => conversation.isUnread);
    const rest = visible.filter((conversation) => !conversation.isUnread);
    const recent = rest.filter((conversation) =>
      this.isRecentConversation(conversation.lastPostedAt)
    );
    const older = rest.filter(
      (conversation) => !this.isRecentConversation(conversation.lastPostedAt)
    );

    return [
      {
        key: "unread",
        title: unread.length
          ? i18n(themePrefix("messages_inbox.sections.unread"))
          : null,
        conversations: unread.map((conversation) =>
          this.decorateConversation(conversation)
        ),
      },
      {
        key: "recent",
        title: recent.length
          ? i18n(themePrefix("messages_inbox.sections.recent"))
          : null,
        conversations: recent.map((conversation) =>
          this.decorateConversation(conversation)
        ),
      },
      {
        key: "older",
        title: older.length
          ? i18n(themePrefix("messages_inbox.sections.older"))
          : null,
        conversations: older.map((conversation) =>
          this.decorateConversation(conversation)
        ),
      },
    ].filter((section) => section.conversations.length);
  }

  get visibleConversations() {
    const query = this.searchQuery.trim().toLowerCase();

    if (!query) {
      return this.conversations;
    }

    return this.conversations.filter((conversation) => {
      return [
        conversation.title,
        conversation.excerpt,
        conversation.participant?.username,
        conversation.participant?.name,
        conversation.lastPosterUsername,
        ...(conversation.groupNames || []),
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));
    });
  }

  isRecentConversation(dateString) {
    if (!dateString) {
      return false;
    }

    const postedAt = new Date(dateString);
    return Date.now() - postedAt.getTime() < 24 * 60 * 60 * 1000;
  }

  sortConversations(conversations) {
    return [...conversations].sort((left, right) => {
      if (left.isGroup !== right.isGroup) {
        return left.isGroup ? -1 : 1;
      }

      const leftTime = left.lastPostedAt ? new Date(left.lastPostedAt).getTime() : 0;
      const rightTime = right.lastPostedAt ? new Date(right.lastPostedAt).getTime() : 0;

      return rightTime - leftTime;
    });
  }

  conversationHref(conversation) {
    const slug = conversation.slug || String(conversation.id);
    return preservePreviewTheme(
      `/t/${encodeURIComponent(slug)}/${conversation.id}`,
      window.location.search
    );
  }

  decorateConversation(conversation) {
    return {
      ...conversation,
      href: this.conversationHref(conversation),
    };
  }

  @action
  async loadConversations(filter, groupName = null, groupFilter = "inbox") {
    const username = this.currentUser?.username;

    if (!username) {
      this.conversations = [];
      this.isLoading = false;
      return;
    }

    if (filter === "groups" && !groupName) {
      this.conversations = [];
      this.isLoading = false;
      return;
    }

    this.isLoading = true;
    this.conversations = await fetchConversationList(
      username,
      groupName ? groupFilter : filter,
      0,
      {
        inbox: groupName ? "group" : "user",
        groupName,
      }
    );
    this.isLoading = false;
  }

  @action
  selectFilter(filter) {
    setMessagesState({
      filter,
      activeGroupName: null,
      activeGroupFilter: "inbox",
      searchQuery: "",
    });

    if (filter !== "groups") {
      DiscourseURL.routeTo(
        preservePreviewTheme(
          userMessagesPath(this.currentUser?.username, filter),
          window.location.search
        )
      );
    }
  }

  @action
  selectGroup(groupName) {
    setMessagesState({
      filter: "groups",
      activeGroupName: groupName,
      activeGroupFilter: "inbox",
      searchQuery: "",
    });

    DiscourseURL.routeTo(
      preservePreviewTheme(
        groupMessagesPath(this.currentUser?.username, groupName),
        window.location.search
      )
    );
  }

  @action
  openNewMessage() {
    DiscourseURL.routeTo("/new-message");
  }

  @action
  updateSearch(event) {
    setMessagesState({ searchQuery: event.target.value });
  }

  <template>
    <div class="fomio-messages-master-container">
      <header class="fomio-messages-master-header">
        <div class="fomio-messages-header-row">
          <h1 class="fomio-messages-title">{{this.titleLabel}}</h1>
          <button
            type="button"
            class="fomio-messages-new-button"
            aria-label={{this.newMessageAriaLabel}}
            title={{this.newMessageLabel}}
            {{on "click" this.openNewMessage}}
          >
            +
          </button>
        </div>

        <nav
          class="fomio-messages-filters"
          aria-label={{this.filtersAriaLabel}}
        >
          {{#each this.filters as |filter|}}
            <button
              type="button"
              class="fomio-messages-filter {{if (eq this.activeFilter filter.key) 'fomio-messages-filter--active'}}"
              {{on "click" (fn this.selectFilter filter.key)}}
            >
              {{filter.label}}
            </button>
          {{/each}}
        </nav>

        <label class="fomio-messages-search">
          <span class="sr-only">{{this.searchLabel}}</span>
          <input
            type="search"
            placeholder={{this.searchPlaceholder}}
            value={{this.searchQuery}}
            {{on "input" this.updateSearch}}
          />
        </label>
      </header>

      <div class="fomio-conversation-list">
        {{#if this.isLoading}}
          <div class="fomio-loading-skeleton">{{this.loadingListMessage}}</div>
        {{else if (eq this.activeFilter "groups")}}
          {{#if this.groupInboxes.length}}
            <section class="fomio-messages-group-panel">
              <div class="fomio-messages-section-heading">
                <h2>{{this.groupsHeading}}</h2>
                <p>{{this.groupsDescription}}</p>
              </div>

              <div class="fomio-group-inbox-list">
                {{#each this.groupInboxes as |group|}}
                  <button
                    type="button"
                    class="fomio-group-inbox-card {{if (eq this.activeGroupName group.name) 'fomio-group-inbox-card--active'}}"
                    {{on "click" (fn this.selectGroup group.name)}}
                  >
                    <span class="fomio-group-inbox-card__avatar">👥</span>
                    <span class="fomio-group-inbox-card__body">
                      <span class="fomio-group-inbox-card__name">
                        {{if group.full_name group.full_name group.name}}
                      </span>
                      <span class="fomio-group-inbox-card__meta">
                        {{this.groupCardMeta}}
                      </span>
                    </span>
                  </button>
                {{/each}}
              </div>
            </section>
          {{else}}
            <div class="fomio-messages-empty-state-card">
              <p class="fomio-messages-empty-title">{{this.groupsEmptyMessage}}</p>
              <p class="fomio-messages-empty-copy">{{this.emptyStateBodyMessage}}</p>
            </div>
          {{/if}}
        {{else if this.visibleConversations.length}}
          <section class="fomio-messages-list-shell">
            {{#each this.conversationSections as |section|}}
              <div class="fomio-conversation-section">
                {{#if section.title}}
                  <div class="fomio-conversation-section__title">
                    {{section.title}}
                  </div>
                {{/if}}

                {{#each section.conversations as |convo|}}
                  <FomioConversationCard
                    @conversation={{convo}}
                    @href={{convo.href}}
                    @isActive={{false}}
                  />
                {{/each}}
              </div>
            {{/each}}
          </section>
        {{else}}
          <div class="fomio-messages-empty-state-card">
            <p class="fomio-messages-empty-title">{{this.emptyStateMessage}}</p>
            <p class="fomio-messages-empty-copy">{{this.emptyStateBodyMessage}}</p>
            <button
              type="button"
              class="fomio-messages-empty-action"
              {{on "click" this.openNewMessage}}
            >
              {{this.newMessageLabel}}
            </button>
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
