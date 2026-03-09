import Component from "@glimmer/component";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioTopicReadingMeta extends Component {
  get topic() {
    return this.args.outletArgs.model;
  }

  get author() {
    return this.topic?.details?.created_by;
  }

  get publishedLabel() {
    return i18n(themePrefix("topic_page.published"));
  }

  get updatedLabel() {
    return i18n(themePrefix("topic_page.updated"));
  }

  get readingLabel() {
    return i18n(themePrefix("topic_page.reading_label"));
  }

  get readingCopy() {
    return i18n(themePrefix("topic_page.reading_copy"));
  }

  <template>
    <section class="fomio-topic-reading-meta">
      {{#if this.author}}
        <div class="fomio-topic-reading-meta__trust">
          <UserLink @user={{this.author}} class="fomio-topic-reading-meta__author">
            {{avatar this.author imageSize="small"}}
            <span class="fomio-topic-reading-meta__author-name">
              {{this.author.username}}
            </span>
          </UserLink>

          <span class="fomio-topic-reading-meta__date">
            <span class="fomio-topic-reading-meta__label">{{this.publishedLabel}}</span>
            {{formatDate this.topic.created_at format="tiny" noTitle="true"}}
          </span>

          <span class="fomio-topic-reading-meta__date">
            <span class="fomio-topic-reading-meta__label">{{this.updatedLabel}}</span>
            {{formatDate this.topic.bumped_at format="tiny" noTitle="true"}}
          </span>
        </div>
      {{/if}}

      <p class="fomio-topic-reading-meta__reading-note">
        <span class="fomio-topic-reading-meta__label">{{this.readingLabel}}</span>
        {{this.readingCopy}}
      </p>
    </section>
  </template>
}
