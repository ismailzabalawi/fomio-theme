import Component from "@glimmer/component";
import { settings } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioTopicAppHandoff extends Component {
  get topic() {
    return this.args.outletArgs.topic;
  }

  get appUrl() {
    return settings.fomio_app_url?.trim();
  }

  get hasAppUrl() {
    return Boolean(this.appUrl);
  }

  // Deep-links directly to the Byte the user is reading: fomio://byte/:id
  get deepLink() {
    const id = this.topic?.id;
    if (!this.appUrl || !id) return this.appUrl;
    return `${this.appUrl}byte/${id}`;
  }

  get shouldRender() {
    return this.hasAppUrl && !this.topic?.isPrivateMessage;
  }

  get title() {
    return i18n(themePrefix("topic_page.handoff_title"));
  }

  get copy() {
    return i18n(themePrefix("topic_page.handoff_copy"));
  }

  get action() {
    return i18n(themePrefix("topic_page.handoff_action"));
  }

  <template>
    {{#if this.shouldRender}}
      <section class="fomio-topic-app-handoff">
        <div class="fomio-topic-app-handoff__content">
          <p class="fomio-topic-app-handoff__eyebrow">{{this.title}}</p>
          <p class="fomio-topic-app-handoff__copy">{{this.copy}}</p>
        </div>
        <a
          class="fomio-topic-app-handoff__action"
          href={{this.deepLink}}
          target="_blank"
          rel="noopener noreferrer"
        >
          {{this.action}}
        </a>
      </section>
    {{/if}}
  </template>
}
