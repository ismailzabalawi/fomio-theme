import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import FomioAvatar from "./fomio-avatar";

export default class FomioUserProfileSummary extends Component {
  get user() {
    return this.args.user;
  }

  get displayName() {
    return this.user?.name || this.user?.username || "";
  }

  get usernameMeta() {
    const username = this.user?.username;
    if (!username) {
      return null;
    }

    const normalizedName = (this.user?.name || "").trim().toLowerCase();
    if (normalizedName === username.trim().toLowerCase()) {
      return null;
    }

    return `@${username}`;
  }

  get metaLine() {
    return this.user?.title || this.usernameMeta || null;
  }

  get href() {
    return this.args.href;
  }

  <template>
    <div class="fomio-user-profile-summary">
      {{#if this.href}}
        <a href={{this.href}} class="fomio-me-hub__summary-link">
          <span class="fomio-me-hub__summary-avatar" aria-hidden="true">
            <FomioAvatar @user={{this.user}} @size="lg" />
          </span>
          <span class="fomio-me-hub__summary-text">
            <span class="fomio-me-hub__summary-name">{{this.displayName}}</span>
            {{#if this.metaLine}}
              <span class="fomio-me-hub__summary-meta">{{this.metaLine}}</span>
            {{/if}}
          </span>
          <span class="fomio-me-hub__summary-chevron" aria-hidden="true">
            {{icon "angle-right"}}
          </span>
        </a>
      {{else}}
        <div class="fomio-me-hub__summary-link fomio-me-hub__summary-link--static">
          <span class="fomio-me-hub__summary-avatar" aria-hidden="true">
            <FomioAvatar @user={{this.user}} @size="lg" />
          </span>
          <span class="fomio-me-hub__summary-text">
            <span class="fomio-me-hub__summary-name">{{this.displayName}}</span>
            {{#if this.metaLine}}
              <span class="fomio-me-hub__summary-meta">{{this.metaLine}}</span>
            {{/if}}
          </span>
        </div>
      {{/if}}
    </div>
  </template>
}
