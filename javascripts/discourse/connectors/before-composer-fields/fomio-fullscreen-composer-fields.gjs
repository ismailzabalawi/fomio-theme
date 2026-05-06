import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { hash } from "@ember/helper";
import { service } from "@ember/service";
import ComposerTitle from "discourse/components/composer-title";
import PopupInputTip from "discourse/components/popup-input-tip";
import MiniTagChooser from "discourse/select-kit/components/mini-tag-chooser";
import CategoryChooser from "discourse/select-kit/components/category-chooser";

export default class FomioFullscreenComposerFields extends Component {
  @service composer;

  get model() {
    return this.args.outletArgs.model;
  }

  get shouldRender() {
    return this.model?.viewFullscreen && this.model?.canEditTitle;
  }

  <template>
    {{#if this.shouldRender}}
      <div class="title-and-category fomio-fullscreen-composer-fields">
        <ComposerTitle
          @composer={{this.model}}
          @lastValidatedAt={{this.composer.lastValidatedAt}}
          @focusTarget={{this.composer.focusTarget}}
        />

        {{#if this.model.showCategoryChooser}}
          <div class="category-input">
            <CategoryChooser
              @value={{this.model.categoryId}}
              @onChange={{this.composer.updateCategory}}
              @options={{hash
                disabled=this.composer.disableCategoryChooser
                scopedCategoryId=this.composer.scopedCategoryId
                prioritizedCategoryId=this.composer.prioritizedCategoryId
                readOnlyCategoryId=this.composer.readOnlyCategoryId
              }}
            />
            <PopupInputTip
              @validation={{this.composer.categoryValidation}}
            />
          </div>
        {{/if}}

        {{#if this.composer.canEditTags}}
          <div class="tags-input">
            <MiniTagChooser
              @value={{this.model.tags}}
              @onChange={{fn (mut this.model.tags)}}
              @options={{hash
                disabled=this.composer.disableTagsChooser
                categoryId=this.model.categoryId
                minimum=this.model.minimumRequiredTags
              }}
            />
            <PopupInputTip
              @validation={{this.composer.tagValidation}}
            />
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
