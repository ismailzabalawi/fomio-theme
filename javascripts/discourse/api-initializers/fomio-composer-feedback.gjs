import Component from "@glimmer/component";
import { get } from "@ember/object";
import { service } from "@ember/service";
import { apiInitializer } from "discourse/lib/api";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

// Presentation only. Core still owns draft saving, conflicts and closing.
// Read the classic model with `get` so changes made by core's `set` rerender.
class FomioComposerFeedback extends Component {
  @service site;

  get status() {
    const model = this.args.outletArgs?.model;
    return model ? get(model, "draftStatus") : null;
  }

  get isOfflineDraft() {
    return this.status === i18n("composer.drafts_offline");
  }

  get showStatus() {
    return this.status && (this.site.mobileView || this.isOfflineDraft);
  }

  get warning() {
    return i18n(themePrefix("composer.unsaved_close_warning"));
  }

  <template>
    {{! Keep the live region mounted before its content changes. }}
    <div
      class="fomio-composer-feedback"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      {{#if this.showStatus}}
        <div class="fomio-composer-feedback__message {{if this.isOfflineDraft '--offline'}}">
          {{dIcon "triangle-exclamation"}}
          <div class="fomio-composer-feedback__text">
            <span>{{this.status}}</span>
            {{#if this.isOfflineDraft}}
              <p>{{this.warning}}</p>
            {{/if}}
          </div>
        </div>
      {{/if}}
    </div>
  </template>
}

export default apiInitializer((api) => {
  // Both composer layouts render this outlet with the same native model.
  api.renderInOutlet("before-composer-fields", FomioComposerFeedback);
});
