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

  get shouldRenderExcerpt() {
    return this.topic.excerpt && !this.args.outletArgs.expandPinned;
  }

  get publishedLabel() {
    return i18n(themePrefix("topic_list.published"));
  }

  get updatedLabel() {
    return i18n(themePrefix("topic_list.updated"));
  }

  <template>
    <div class="fomio-topic-context">
      {{#if this.creator}}
        <div class="fomio-topic-context__meta">
          <UserLink @user={{this.creator}} class="fomio-topic-context__author">
            {{avatar this.creator imageSize="small"}}
            <span class="fomio-topic-context__author-name">
              {{this.creator.username}}
            </span>
          </UserLink>

          <span class="fomio-topic-context__date">
            <span class="fomio-topic-context__label">{{this.publishedLabel}}</span>
            {{formatDate this.topic.created_at format="tiny" noTitle="true"}}
          </span>

          <span class="fomio-topic-context__date">
            <span class="fomio-topic-context__label">{{this.updatedLabel}}</span>
            {{formatDate this.topic.bumpedAt format="tiny" noTitle="true"}}
          </span>
        </div>
      {{/if}}

      {{#if this.shouldRenderExcerpt}}
        <TopicExcerpt @topic={{this.topic}} class="fomio-topic-context__excerpt" />
      {{/if}}
    </div>
  </template>
}
