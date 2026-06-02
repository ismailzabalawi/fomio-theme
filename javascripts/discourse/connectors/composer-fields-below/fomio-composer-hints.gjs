import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Connector: composer-fields-below
 *
 * Keyboard-hint legend on the left of the submit row (⌘↵ publish · esc close)
 * for the full-page Create / Edit surface. Reply keeps the native sheet, so
 * this renders nothing for replies. Hints are advisory text only — the actual
 * shortcuts are owned by Discourse.
 */
export default class FomioComposerHints extends Component {
  get model() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    const model = this.model;
    return Boolean(model && (model.creatingTopic || model.editingPost));
  }

  get submitLabel() {
    return this.model?.editingPost
      ? i18n(themePrefix("composer.shortcut_save"))
      : i18n(themePrefix("composer.shortcut_publish"));
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-composer-hints" aria-hidden="true">
        <span class="fomio-composer-hints__item">
          <kbd>⌘</kbd><kbd>↵</kbd>
          {{this.submitLabel}}
        </span>
        <span class="fomio-composer-hints__item">
          <kbd>esc</kbd>
          {{i18n (themePrefix "composer.hint_close")}}
        </span>
      </div>
    {{/if}}
  </template>
}
