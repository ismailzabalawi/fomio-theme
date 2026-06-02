import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Connector: composer-open
 *
 * Reading-context card shown above the reply sheet: the teret tag and the
 * title of the byte being replied to. Minimal by design — author/excerpt are
 * unreliable from composer model state, so we show only what `model.topic`
 * reliably carries. Renders only for replies.
 */
export default class FomioComposerReplyContext extends Component {
  get model() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    const model = this.model;
    return Boolean(model && model.replyingToTopic && model.topic?.title);
  }

  get title() {
    return this.model?.topic?.title;
  }

  get teretName() {
    return this.model?.topic?.category?.name ?? null;
  }

  get teretColor() {
    return this.model?.topic?.category?.color ?? null;
  }

  <template>
    {{#if this.shouldRender}}
      <article class="fomio-composer-byte-context">
        {{#if this.teretName}}
          <span class="fomio-composer-byte-context__teret">
            {{#if this.teretColor}}
              <span
                class="fomio-composer-byte-context__swatch"
                style="background: #{{this.teretColor}}"
                aria-hidden="true"
              ></span>
            {{/if}}
            {{this.teretName}}
          </span>
        {{/if}}
        <h2 class="fomio-composer-byte-context__title">{{this.title}}</h2>
        <span class="fomio-composer-byte-context__replying">
          {{icon "reply"}}
          {{i18n (themePrefix "composer.replying_to")}}
        </span>
      </article>
    {{/if}}
  </template>
}
