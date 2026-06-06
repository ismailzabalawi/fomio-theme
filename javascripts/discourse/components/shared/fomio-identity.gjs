import Component from "@glimmer/component";
import FomioAvatar from "./fomio-avatar";
import {
  identityClassNames,
  normalizeIdentitySize,
} from "../../lib/fomio-content-classes";

export default class FomioIdentity extends Component {
  get className() {
    return identityClassNames(this.args);
  }

  get name() {
    return this.args.name || this.args.user?.name || this.args.user?.username || "";
  }

  get handle() {
    if (this.args.showHandle === false) {
      return null;
    }

    if (this.args.handle) {
      return this.args.handle;
    }

    const username = this.args.user?.username;
    return username ? `@${username}` : null;
  }

  get size() {
    return normalizeIdentitySize(this.args);
  }

  get avatarSize() {
    return this.args.avatarSize || (this.size === "lg" ? "lg" : "sm");
  }

  get palette() {
    return this.args.palette || "terra";
  }

  get showAvatar() {
    return this.args.showAvatar !== false;
  }

  <template>
    <span class={{this.className}}>
      {{#if this.showAvatar}}
        <FomioAvatar
          @user={{@user}}
          @size={{this.avatarSize}}
          @palette={{this.palette}}
          @initials={{@initials}}
          @badgeCount={{@badgeCount}}
          @online={{@online}}
        />
      {{/if}}
      <span class="fomio-identity__meta">
        <span class="fomio-identity__name">{{this.name}}</span>
        {{#if this.handle}}
          <span class="fomio-identity__handle">{{this.handle}}</span>
        {{/if}}
        {{#if @role}}
          <span class="fomio-identity__role">{{@role}}</span>
        {{/if}}
      </span>
    </span>
  </template>
}
