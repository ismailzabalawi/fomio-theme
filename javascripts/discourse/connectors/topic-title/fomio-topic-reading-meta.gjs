import Component from "@glimmer/component";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import formatDate from "discourse/helpers/format-date";

export default class FomioTopicReadingMeta extends Component {
  get topic() {
    return this.args.outletArgs.model;
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

  <template>
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
            {{avatar this.author imageSize="small"}}
            <span class="fomio-topic-reading-meta__author-name">
              {{this.author.username}}
            </span>
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
  </template>
}
