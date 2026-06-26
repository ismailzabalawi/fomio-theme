import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioAvatar from "./shared/fomio-avatar";

export default class FomioActivityProfileStrip extends Component {
  @service router;

  get shouldRender() {
    return Boolean(this.router.currentRouteName?.startsWith("userActivity") && this.user);
  }

  get user() {
    const model = this.args.outletArgs?.model;
    if (!model) return null;
    return model.user ?? model;
  }

  get displayName() {
    return this.user?.name || this.user?.username || "";
  }

  get handle() {
    const u = this.user?.username;
    return u ? `@${u}` : null;
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-activity-strip" aria-hidden="true">
        <span class="fomio-activity-strip__avatar-wrap">
          <FomioAvatar
            @user={{this.user}}
            @size="md"
            @palette="terra"
          />
        </span>
        <span class="fomio-activity-strip__meta">
          <span class="fomio-activity-strip__name">{{this.displayName}}</span>
          {{#if this.handle}}
            <span class="fomio-activity-strip__handle">{{this.handle}}</span>
          {{/if}}
        </span>
      </div>
    {{/if}}
  </template>
}
