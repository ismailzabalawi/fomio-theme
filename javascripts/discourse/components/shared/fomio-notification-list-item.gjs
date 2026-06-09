import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import replaceEmoji from "discourse/helpers/replace-emoji";

export default class FomioNotificationListItem extends Component {
  get description() {
    const description = this.args.description;
    if (description) {
      return replaceEmoji(description);
    }
  }

  <template>
    <li class={{@className}}>
      <a
        href={{@href}}
        title={{@title}}
        {{on "click" @onClick}}
      >
        {{#if @iconComponent}}
          <@iconComponent @data={{@iconComponentArgs}} />
        {{else}}
          {{icon @icon}}
        {{/if}}

        <div>
          {{#if @label}}
            <span class={{concat "item-label " @labelClass}}>
              {{@label}}
            </span>
          {{/if}}

          {{#if this.description}}
            <span
              class={{concat "item-description " @descriptionClass}}
              data-topic-id={{@topicId}}
            >
              {{this.description}}
            </span>
          {{/if}}
        </div>

        {{#if @endComponent}}
          <@endComponent />
        {{/if}}
      </a>
    </li>
  </template>
}
