import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { settings, themePrefix } from "virtual:theme";
import { and } from "discourse/truth-helpers";

/**
 * Verified outlet: discourse/frontend/discourse/app/components/topic-footer-buttons.gjs
 * @name after-topic-footer-buttons — outletArgs.topic
 */
export default class FomioTopicAppHandoff extends Component {
  @service site;

  get topic() {
    return this.args.outletArgs?.topic;
  }

  get appByteUrl() {
    const id = this.topic?.id;
    if (!id) {
      return null;
    }
    const base = settings.fomio_app_url || "fomio://";
    return `${base}byte/${id}`;
  }

  <template>
    {{#if (and this.site.mobileView this.appByteUrl)}}
      <div class="fomio-topic-app-handoff">
        <p class="fomio-topic-app-handoff__title">
          {{i18n (themePrefix "topic_page.handoff_title")}}
        </p>
        <p class="fomio-topic-app-handoff__copy">
          {{i18n (themePrefix "topic_page.handoff_copy")}}
        </p>
        <a
          href={{this.appByteUrl}}
          class="btn btn-primary fomio-topic-app-handoff__action"
        >
          {{i18n (themePrefix "topic_page.handoff_action")}}
        </a>
      </div>
    {{/if}}
  </template>
}
