import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import TopicExcerpt from "discourse/components/topic-list/topic-excerpt";
import UserLink from "discourse/components/user-link";
import formatDate from "discourse/helpers/format-date";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioCard from "./fomio-card";
import FomioIdentity from "./fomio-identity";

export default class FomioByteCard extends Component {
  get topic() {
    return this.args.topic;
  }

  get creator() {
    return this.topic?.creator;
  }

  get teret() {
    return this.topic?.category?.name ?? null;
  }

  get readTime() {
    const words = this.topic?.word_count ?? this.topic?.wordCount ?? 0;
    if (!words) {
      return null;
    }

    return Math.max(1, Math.ceil(words / 200));
  }

  get replyCount() {
    return this.topic?.reply_count ?? this.topic?.replyCount ?? 0;
  }

  get likeCount() {
    return this.topic?.like_count ?? this.topic?.likeCount ?? 0;
  }

  get isPinned() {
    return Boolean(this.topic?.pinned || this.topic?.pinned_globally);
  }

  get isUnread() {
    return Boolean((this.topic?.unread_posts ?? 0) > 0 || this.topic?.unseen);
  }

  get topicImage() {
    return this.topic?.image_url ?? null;
  }

  get variant() {
    const variant = this.args.variant;

    if (["feature", "compact"].includes(variant)) {
      return variant;
    }

    return "standard";
  }

  get shouldRenderExcerpt() {
    return Boolean(this.topic?.excerpt);
  }

  get titleHtml() {
    return htmlSafe(this.topic?.fancyTitle ?? this.topic?.title ?? "");
  }

  get url() {
    if (this.topic?.linked_post_number) {
      return this.topic.urlForPostNumber(this.topic.linked_post_number);
    }

    return this.topic?.lastUnreadUrl ?? this.topic?.url;
  }

  get byteClass() {
    const classes = ["byte", "fomio-topic-context"];

    if (this.topicImage) {
      classes.push("fomio-topic-context--has-image");
    }

    if (this.variant === "feature") {
      classes.push("byte--feature");
    } else if (this.variant === "compact") {
      classes.push("byte--compact");
    } else if (!this.topicImage) {
      classes.push("byte--no-thumb");
    }

    if (this.isUnread) {
      classes.push("is-unread");
    }

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
  }

  get slotClass() {
    const classes = ["byte-slot"];

    if (this.args.slotClass) {
      classes.push(this.args.slotClass);
    }

    return classes.join(" ");
  }

  <template>
    <div class={{this.slotClass}}>
      <FomioCard
        @tag="article"
        @surface="flat"
        @extraClass={{this.byteClass}}
      >
        <div class="byte__body">
          <div class="byte__meta fomio-topic-context__meta">
            {{#if this.teret}}
              <span class="byte__teret fomio-topic-context__teret">{{this.teret}}</span>
            {{/if}}
            {{#if this.isPinned}}
              <span class="byte__dot fomio-topic-context__meta-dot" aria-hidden="true"></span>
              <span class="byte__pin fomio-topic-context__pin">
                {{icon "thumbtack"}}
                {{i18n (themePrefix "topic_list.pinned")}}
              </span>
            {{/if}}
            {{#if this.readTime}}
              <span class="byte__dot fomio-topic-context__meta-dot" aria-hidden="true"></span>
              <span class="byte__read-time fomio-topic-context__read-time">
                {{this.readTime}} {{i18n (themePrefix "topic_list.min_read")}}
              </span>
            {{/if}}
          </div>

          <a href={{this.url}} class="byte__title">
            {{this.titleHtml}}
          </a>

          {{#if this.shouldRenderExcerpt}}
            <div class="byte__excerpt fomio-topic-context__text">
              <TopicExcerpt @topic={{this.topic}} class="fomio-topic-context__excerpt" />
            </div>
          {{/if}}

          <div class="byte__footer fomio-topic-context__footer">
            {{#if this.creator}}
              <UserLink @user={{this.creator}} class="byte__author fomio-topic-context__author">
                <FomioIdentity
                  @user={{this.creator}}
                  @name={{this.creator.username}}
                  @showHandle={{false}}
                  @avatarSize="sm"
                />
              </UserLink>
              <span class="byte__sep fomio-topic-context__sep" aria-hidden="true"></span>
            {{/if}}

            <span class="byte__stat fomio-topic-context__stat" aria-label="{{this.replyCount}} replies">
              {{icon "comment"}}
              {{this.replyCount}}
            </span>

            <span class="byte__stat fomio-topic-context__stat" aria-label="{{this.likeCount}} likes">
              {{icon "heart"}}
              {{this.likeCount}}
            </span>

            {{#if this.creator}}
              <span class="byte__sep fomio-topic-context__sep" aria-hidden="true"></span>
              <span class="byte__time fomio-topic-context__date">
                {{formatDate this.topic.created_at format="medium" noTitle="true"}}
              </span>
            {{/if}}

            {{#if this.isUnread}}
              <span class="byte__unread fomio-topic-context__unread" aria-label="Unread"></span>
            {{/if}}
          </div>
        </div>

        {{#if this.topicImage}}
          <div class="byte__hero fomio-topic-context__thumb">
            <img src={{this.topicImage}} alt="" loading="lazy" />
          </div>
        {{/if}}
      </FomioCard>
    </div>
  </template>
}
