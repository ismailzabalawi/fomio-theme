import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
import ageWithTooltip from "discourse/helpers/age-with-tooltip";
import icon from "discourse/helpers/d-icon";
import HtmlWithLinks from "discourse/components/html-with-links";
import FomioAvatar from "./fomio-avatar";

export default class FomioUserProfileSummary extends Component {
  get user() {
    return this.args.user;
  }

  get displayName() {
    const user = this.user;
    return (user?.name && String(user.name).trim()) || user?.username || "";
  }

  get statusLine() {
    const user = this.user;
    if (!user?.username) {
      return null;
    }

    const statusDescription =
      user?.status && typeof user.status.description === "string"
        ? user.status.description.trim()
        : "";

    return statusDescription || `@${user.username}`;
  }

  get eyebrow() {
    return this.args.eyebrow ?? this.user?.title ?? null;
  }

  get websiteLabel() {
    if (this.args.websiteLabel !== undefined) {
      return this.args.websiteLabel;
    }

    const explicitName = this.user?.website_name;
    if (explicitName) {
      return explicitName;
    }

    const rawWebsite = this.user?.website;
    if (!rawWebsite) {
      return null;
    }

    try {
      return new URL(rawWebsite).hostname.replace(/^www\./, "");
    } catch {
      return rawWebsite;
    }
  }

  get bioHtml() {
    const cooked = this.args.bioHtml ?? this.user?.bio_cooked;
    return cooked ? htmlSafe(cooked) : null;
  }

  get showFacts() {
    return Boolean(this.user?.location || this.websiteLabel);
  }

  get markerText() {
    if (this.args.markerText !== undefined) {
      return this.args.markerText;
    }

    if (this.user?.admin) {
      return "Discourse Admin";
    }

    if (this.user?.moderator) {
      return "Moderator";
    }

    return null;
  }

  get stats() {
    return this.args.stats ?? [];
  }

  get detailsItems() {
    return this.args.detailsItems ?? [];
  }

  get showDetails() {
    return Boolean(this.args.showDetails && this.detailsItems.length);
  }

  get showExpand() {
    return Boolean(this.args.showExpand && this.args.onToggleExpand);
  }

  get showAdminAction() {
    return Boolean(this.args.adminHref && this.args.adminLabel);
  }

  get hasHeaderControls() {
    return this.showExpand || this.showAdminAction;
  }

  get adminFirst() {
    return Boolean(this.args.adminFirst);
  }

  get expandButtonIcon() {
    return this.args.expandButtonIcon ?? "angles-down";
  }

  get expandButtonLabel() {
    return this.args.expandButtonLabel ?? "Expand";
  }

  get expandButtonAriaLabel() {
    return this.args.expandButtonAriaLabel ?? this.expandButtonLabel;
  }

  get useHubStyleExpandToggle() {
    return this.args.expandButtonStyle === "hub-toggle";
  }

  get expandButtonClass() {
    let className =
      "fomio-me-hub__summary-action fomio-me-hub__summary-action--secondary user-profile-toggle-btn";

    if (this.useHubStyleExpandToggle) {
      className += " fomio-me-hub__summary-action--toggle";
    }

    if (this.args.showDetails) {
      className += " is-open";
    }

    return className;
  }

  get renderedExpandButtonIcon() {
    return this.useHubStyleExpandToggle ? "angle-right" : this.expandButtonIcon;
  }

  <template>
    <div class="fomio-user-profile-summary">
      <div class="fomio-me-hub__summary">
        <div class="fomio-me-hub__summary-link fomio-me-hub__summary-link--static">
          <span class="fomio-me-hub__summary-avatar" aria-hidden="true">
            <FomioAvatar @user={{this.user}} @size="lg" />
          </span>
          <span class="fomio-me-hub__summary-text">
            <span class="fomio-me-hub__summary-name-row">
              <span class="fomio-me-hub__summary-name">{{this.displayName}}</span>
              {{#if this.markerText}}
                <span class="fomio-me-hub__summary-marker">
                  <span class="fomio-me-hub__summary-marker-icon" aria-hidden="true">{{icon
                      "shield-halved"
                    }}</span>
                  <span class="fomio-me-hub__summary-marker-copy">{{this.markerText}}</span>
                </span>
              {{/if}}
            </span>

            {{#if this.statusLine}}
              <span class="fomio-me-hub__summary-meta">{{this.statusLine}}</span>
            {{/if}}

            {{#if this.eyebrow}}
              <span class="fomio-me-hub__summary-kicker">{{this.eyebrow}}</span>
            {{/if}}

            {{#if this.showFacts}}
              <span class="fomio-me-hub__summary-facts">
                {{#if this.user.location}}
                  <span class="fomio-me-hub__summary-fact">
                    <span class="fomio-me-hub__summary-fact-icon" aria-hidden="true">{{icon
                        "location-dot"
                      }}</span>
                    <span class="fomio-me-hub__summary-fact-copy">{{this.user.location}}</span>
                  </span>
                {{/if}}
                {{#if this.websiteLabel}}
                  <span class="fomio-me-hub__summary-fact">
                    <span class="fomio-me-hub__summary-fact-icon" aria-hidden="true">{{icon
                        "globe"
                      }}</span>
                    <span class="fomio-me-hub__summary-fact-copy">{{this.websiteLabel}}</span>
                  </span>
                {{/if}}
              </span>
            {{/if}}

            {{#if this.bioHtml}}
              <span class="fomio-me-hub__summary-bio">
                <HtmlWithLinks>
                  {{this.bioHtml}}
                </HtmlWithLinks>
              </span>
            {{/if}}

            {{#if this.stats.length}}
              <span class="fomio-me-hub__summary-stats">
                {{#each this.stats as |stat|}}
                  <span class="fomio-me-hub__summary-stat">
                    <span class="fomio-me-hub__summary-stat-icon" aria-hidden="true">{{icon
                        stat.icon
                      }}</span>
                    <span class="fomio-me-hub__summary-stat-copy">{{stat.value}}
                      {{stat.label}}</span>
                  </span>
                {{/each}}
              </span>
            {{/if}}
          </span>
        </div>

        {{#if this.hasHeaderControls}}
          <div class="fomio-me-hub__summary-actions">
            {{#if this.adminFirst}}
              {{#if this.showAdminAction}}
                <a
                  href={{this.args.adminHref}}
                  class="fomio-me-hub__summary-action fomio-me-hub__summary-action--secondary"
                >
                  <span class="fomio-me-hub__summary-action-icon" aria-hidden="true">{{icon
                      "wrench"
                    }}</span>
                  <span class="fomio-me-hub__summary-action-label">{{this.args.adminLabel}}</span>
                </a>
              {{/if}}
            {{/if}}

            {{#if this.showExpand}}
              <button
                type="button"
                class={{this.expandButtonClass}}
                aria-controls="collapsed-info-panel"
                aria-expanded={{if this.args.showDetails "true" "false"}}
                aria-label={{this.expandButtonAriaLabel}}
                title={{this.expandButtonLabel}}
                {{on "click" this.args.onToggleExpand}}
              >
                <span class="fomio-me-hub__summary-action-icon" aria-hidden="true">{{icon
                    this.renderedExpandButtonIcon
                  }}</span>
                {{#unless this.useHubStyleExpandToggle}}
                  <span class="fomio-me-hub__summary-action-label">{{this.expandButtonLabel}}</span>
                {{/unless}}
              </button>
            {{/if}}

            {{#unless this.adminFirst}}
              {{#if this.showAdminAction}}
                <a
                  href={{this.args.adminHref}}
                  class="fomio-me-hub__summary-action fomio-me-hub__summary-action--secondary"
                >
                  <span class="fomio-me-hub__summary-action-icon" aria-hidden="true">{{icon
                      "wrench"
                    }}</span>
                  <span class="fomio-me-hub__summary-action-label">{{this.args.adminLabel}}</span>
                </a>
              {{/if}}
            {{/unless}}
          </div>
        {{/if}}
      </div>

      {{#if this.showDetails}}
        <div class="fomio-me-hub__details is-open" id="collapsed-info-panel">
          <dl>
            {{#each this.detailsItems as |item|}}
              <div>
                <dt>{{item.label}}</dt>
                <dd>
                  {{#if item.date}}
                    {{ageWithTooltip item.date format="medium"}}
                  {{else}}
                    {{item.value}}
                  {{/if}}
                </dd>
              </div>
            {{/each}}
          </dl>
        </div>
      {{/if}}
    </div>
  </template>
}
