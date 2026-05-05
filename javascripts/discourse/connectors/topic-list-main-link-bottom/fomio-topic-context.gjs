import Component from "@glimmer/component";
import TopicExcerpt from "discourse/components/topic-list/topic-excerpt";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioTopicContext extends Component {
  get topic() {
    return this.args.outletArgs.topic;
  }

  get creator() {
    return this.topic.creator;
  }

  get teret() {
    return this.topic.category?.name ?? null;
  }

  get readTime() {
    const words = this.topic.word_count ?? this.topic.wordCount ?? 0;
    if (!words) return null;
    return Math.max(1, Math.ceil(words / 200));
  }

  get replyCount() {
    return this.topic.reply_count ?? this.topic.replyCount ?? 0;
  }

  get likeCount() {
    return this.topic.like_count ?? this.topic.likeCount ?? 0;
  }

  get isPinned() {
    return !!(this.topic.pinned || this.topic.pinned_globally);
  }

  get isUnread() {
    return !!((this.topic.unread_posts ?? 0) > 0 || this.topic.unseen);
  }

  get shouldRenderExcerpt() {
    return !!this.topic.excerpt;
  }

  get topicImage() {
    return this.topic.image_url ?? null;
  }

  <template>
    {{!--
      The four direct children become grid items inside td.main-link (display: grid)
      via `display: contents` applied to .fomio-topic-context in CSS.
      Grid areas: meta (above title) · text · footer · thumb (right column).
    --}}
    <div class="fomio-topic-context {{if this.topicImage 'fomio-topic-context--has-image'}}">

      {{!-- Meta: teret badge · read time · pinned — grid-area: meta, sits ABOVE the title --}}
      <div class="fomio-topic-context__meta">
        {{#if this.teret}}
          <span class="fomio-topic-context__teret">{{this.teret}}</span>
        {{/if}}
        {{#if this.isPinned}}
          <span class="fomio-topic-context__meta-dot" aria-hidden="true"></span>
          <span class="fomio-topic-context__pin">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 17v5M7 4h10l-1.5 4 2.5 2v3H6v-3l2.5-2L7 4Z"/></svg>
            {{i18n (themePrefix "topic_list.pinned")}}
          </span>
        {{/if}}
        {{#if this.readTime}}
          <span class="fomio-topic-context__meta-dot" aria-hidden="true"></span>
          <span class="fomio-topic-context__read-time">{{this.readTime}} {{i18n (themePrefix "topic_list.min_read")}}</span>
        {{/if}}
      </div>

      {{!-- Excerpt — grid-area: text, sits below the Discourse-rendered title --}}
      {{#if this.shouldRenderExcerpt}}
        <div class="fomio-topic-context__text">
          <TopicExcerpt @topic={{this.topic}} class="fomio-topic-context__excerpt" />
        </div>
      {{/if}}

      {{!-- Footer: author · replies · likes · date · unread — grid-area: footer --}}
      <div class="fomio-topic-context__footer">
        {{#if this.creator}}
          <UserLink @user={{this.creator}} class="fomio-topic-context__author">
            {{avatar this.creator imageSize="small"}}
            <span class="fomio-topic-context__author-name">{{this.creator.username}}</span>
          </UserLink>
          <span class="fomio-topic-context__sep" aria-hidden="true"></span>
        {{/if}}
        <span class="fomio-topic-context__stat" aria-label="{{this.replyCount}} replies">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          {{this.replyCount}}
        </span>
        <span class="fomio-topic-context__stat" aria-label="{{this.likeCount}} likes">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.5 7.5a4.5 4.5 0 0 0-8.5-2 4.5 4.5 0 0 0-8.5 2c0 6 8.5 11 8.5 11s8.5-5 8.5-11Z"/></svg>
          {{this.likeCount}}
        </span>
        {{#if this.creator}}
          <span class="fomio-topic-context__sep" aria-hidden="true"></span>
          <span class="fomio-topic-context__date">
            {{formatDate this.topic.created_at format="medium" noTitle="true"}}
          </span>
        {{/if}}
        {{#if this.isUnread}}
          <span class="fomio-topic-context__unread" aria-label="Unread"></span>
        {{/if}}
      </div>

      {{!-- Thumbnail — grid-area: thumb, right column --}}
      {{#if this.topicImage}}
        <img
          class="fomio-topic-context__thumb"
          src={{this.topicImage}}
          alt=""
          loading="lazy"
        />
      {{/if}}

    </div>
  </template>
}
