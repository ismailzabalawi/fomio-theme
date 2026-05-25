import Component from "@glimmer/component";
import FomioAvatar from "./fomio-avatar";

export default class FomioIdentity extends Component {
  get className() {
    const classes = ["fomio-identity"];

    if (this.args.large) {
      classes.push("fomio-identity--lg");
    }

    if (this.args.extraClass) {
      classes.push(this.args.extraClass);
    }

    return classes.join(" ");
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

  get avatarSize() {
    return this.args.avatarSize || (this.args.large ? "lg" : "sm");
  }

  get palette() {
    return this.args.palette || "terra";
  }

  <template>
    <span class={{this.className}}>
      <FomioAvatar
        @user={{@user}}
        @size={{this.avatarSize}}
        @palette={{this.palette}}
        @initials={{@initials}}
        @badgeCount={{@badgeCount}}
        @online={{@online}}
      />
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
