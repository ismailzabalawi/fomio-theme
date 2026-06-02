import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { metricsStore } from "../../lib/fomio-composer-metrics-store";

/**
 * Connector: composer-fields-below
 *
 * IDE-style status bar pinned to the bottom of the full-page Create / Edit
 * surface: live word + character counts, with the submit shortcut on the
 * right. Draft-save state is intentionally left to Discourse's native
 * `#draft-status` (we don't fabricate a timestamp). Renders nothing for
 * replies; hidden on touch (the mobile bar replaces it).
 */
export default class FomioComposerStatusbar extends Component {
  get model() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    const model = this.model;
    return Boolean(model && (model.creatingTopic || model.editingPost));
  }

  get wordsLabel() {
    return metricsStore.words.toLocaleString();
  }

  get charsLabel() {
    return metricsStore.chars.toLocaleString();
  }

  get submitLabel() {
    return this.model?.editingPost
      ? i18n(themePrefix("composer.shortcut_save"))
      : i18n(themePrefix("composer.shortcut_publish"));
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-composer-statusbar" aria-hidden="true">
        <span class="fomio-composer-statusbar__seg">
          {{this.wordsLabel}}
          {{i18n (themePrefix "composer.words")}}
          ·
          {{this.charsLabel}}
          {{i18n (themePrefix "composer.chars")}}
        </span>
        <span class="fomio-composer-statusbar__right">
          <span class="fomio-composer-statusbar__seg">⌘↵ {{this.submitLabel}}</span>
        </span>
      </div>
    {{/if}}
  </template>
}
