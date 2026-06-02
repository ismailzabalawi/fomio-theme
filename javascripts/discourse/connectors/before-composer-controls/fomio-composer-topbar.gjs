import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Connector: before-composer-controls
 *
 * Supplies the editorial topbar (back · mode · close) for the full-page
 * Create / Edit surface. Renders inside `.reply-to`, which the composer SCSS
 * turns into the sticky topbar; Discourse's own toggle controls and action
 * title are hidden there. Reply mode keeps the native bottom sheet, so this
 * renders nothing for replies.
 *
 * All actions route through the supported composer service API — no Ember
 * layer changes.
 */
export default class FomioComposerTopbar extends Component {
  @service composer;

  get model() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    const model = this.model;
    return Boolean(model && (model.creatingTopic || model.editingPost));
  }

  get modeLabel() {
    return this.model?.editingPost
      ? i18n(themePrefix("composer.mode_edit"))
      : i18n(themePrefix("composer.mode_create"));
  }

  get hubName() {
    return this.model?.topic?.category?.name ?? null;
  }

  @action
  close() {
    this.composer.cancel();
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-composer-topbar">
        <button
          type="button"
          class="fomio-composer-topbar__back"
          {{on "click" this.close}}
        >
          {{icon "chevron-left"}}
          <span>
            {{#if this.hubName}}
              {{this.hubName}}
            {{else}}
              {{i18n (themePrefix "composer.back")}}
            {{/if}}
          </span>
        </button>

        <div class="fomio-composer-topbar__mode">
          <span class="fomio-composer-topbar__mode-label">
            {{i18n (themePrefix "composer.mode_label")}}
          </span>
          <b>{{this.modeLabel}}</b>
        </div>

        <button
          type="button"
          class="fomio-composer-topbar__close"
          title={{i18n (themePrefix "composer.close")}}
          aria-label={{i18n (themePrefix "composer.close")}}
          {{on "click" this.close}}
        >
          {{icon "xmark"}}
        </button>
      </div>
    {{/if}}
  </template>
}
