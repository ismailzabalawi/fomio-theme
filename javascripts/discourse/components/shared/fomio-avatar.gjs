import Component from "@glimmer/component";
import avatar from "discourse/helpers/avatar";
import {
  avatarClassNames,
  avatarImageSize,
  hasAvatarBadge,
} from "../../lib/fomio-content-classes";

export default class FomioAvatar extends Component {
  get user() {
    return this.args.user;
  }

  get avatarClass() {
    return avatarClassNames(this.args);
  }

  get initials() {
    const source =
      this.args.initials ||
      this.user?.name ||
      this.user?.username ||
      "";

    return source.trim().charAt(0).toUpperCase();
  }

  get hasBadge() {
    return hasAvatarBadge(this.args);
  }

  get badgeLabel() {
    if (this.args.online) {
      return null;
    }

    return this.args.badgeCount;
  }

  get imageSize() {
    return avatarImageSize(this.args);
  }

  get ariaHidden() {
    return this.args.ariaLabel ? null : "true";
  }

  <template>
    {{#if this.hasBadge}}
      <span class="fomio-avatar-wrap">
        <span
          class={{this.avatarClass}}
          aria-hidden={{this.ariaHidden}}
          aria-label={{@ariaLabel}}
        >
          {{#if this.user}}
            {{avatar this.user imageSize=this.imageSize}}
          {{else}}
            {{this.initials}}
          {{/if}}
        </span>
        <span class="av-badge {{if @online "online"}}">
          {{this.badgeLabel}}
        </span>
      </span>
    {{else}}
      <span
        class={{this.avatarClass}}
        aria-hidden={{this.ariaHidden}}
        aria-label={{@ariaLabel}}
      >
        {{#if this.user}}
          {{avatar this.user imageSize=this.imageSize}}
        {{else}}
          {{this.initials}}
        {{/if}}
      </span>
    {{/if}}
  </template>
}
