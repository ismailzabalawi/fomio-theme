import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { emptyStateClassNames } from "../../lib/fomio-content-classes";

export default class FomioEmptyState extends Component {
  get className() {
    return emptyStateClassNames(this.args);
  }

  <template>
    <div class={{this.className}} ...attributes>
      {{#if @icon}}
        <span class="fomio-empty-state__mark" aria-hidden="true">
          {{icon @icon}}
        </span>
      {{/if}}

      {{#if @title}}
        <h3 class="fomio-empty-state__title">{{@title}}</h3>
      {{/if}}

      {{#if @body}}
        <p class="fomio-empty-state__body">{{@body}}</p>
      {{/if}}

      {{#if (has-block)}}
        <div class="fomio-empty-state__actions">
          {{yield}}
        </div>
      {{/if}}
    </div>
  </template>
}
