import Component from "@glimmer/component";
import avatar from "discourse/helpers/avatar";

const SIZE_CLASSES = {
  xs: "fomio-avatar--xs",
  sm: "fomio-avatar--sm",
  md: "fomio-avatar--md",
  lg: "fomio-avatar--lg",
  xl: "fomio-avatar--xl",
};

const PALETTE_CLASSES = {
  terra: "fomio-avatar--terra",
  violet: "fomio-avatar--violet",
  sage: "fomio-avatar--sage",
  slate: "fomio-avatar--slate",
  warm: "fomio-avatar--warm",
};

export default class FomioAvatar extends Component {
  get user() {
    return this.args.user;
  }

  get sizeClass() {
    return SIZE_CLASSES[this.args.size] || SIZE_CLASSES.md;
  }

  get paletteClass() {
    return PALETTE_CLASSES[this.args.palette] || PALETTE_CLASSES.terra;
  }

  get avatarClass() {
    const classes = ["fomio-avatar", this.sizeClass, this.paletteClass];

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
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
    return Boolean(this.args.online || this.args.badgeCount);
  }

  get badgeLabel() {
    if (this.args.online) {
      return null;
    }

    return this.args.badgeCount;
  }

  <template>
    {{#if this.hasBadge}}
      <span class="fomio-avatar-wrap">
        <span class={{this.avatarClass}} aria-hidden="true">
          {{#if this.user}}
            {{avatar this.user imageSize="large"}}
          {{else}}
            {{this.initials}}
          {{/if}}
        </span>
        <span class="av-badge {{if @online "online"}}">
          {{this.badgeLabel}}
        </span>
      </span>
    {{else}}
      <span class={{this.avatarClass}} aria-hidden="true">
        {{#if this.user}}
          {{avatar this.user imageSize="large"}}
        {{else}}
          {{this.initials}}
        {{/if}}
      </span>
    {{/if}}
  </template>
}
