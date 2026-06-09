import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
import ageWithTooltip from "discourse/helpers/age-with-tooltip";
import icon from "discourse/helpers/d-icon";
import HtmlWithLinks from "discourse/components/html-with-links";
import FomioAvatar from "./fomio-avatar";
import FomioButton from "./fomio-button";
import FomioMetaRow from "./fomio-meta-row";

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
    return this.facts.length > 0;
  }

  get markerText() {
    if (this.args.markerText !== undefined) {
      return this.args.markerText;
    }

    if (this.user?.admin) {
      return "Fomio Admin";
    }

    if (this.user?.moderator) {
      return "Moderator";
    }

    return null;
  }

  get stats() {
    return this.args.stats ?? [];
  }

  get facts() {
    const facts = [];

    if (this.user?.location) {
      facts.push({
        key: "location",
        icon: "location-dot",
        value: this.user.location,
      });
    }

    if (this.websiteLabel) {
      facts.push({
        key: "website",
        icon: "globe",
        value: this.websiteLabel,
      });
    }

    return facts;
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

  get detailsPanelId() {
    return "collapsed-info-panel";
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
    let className = "fomio-me-hub__summary-action user-profile-toggle-btn";

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
              <FomioMetaRow @extraClass="fomio-me-hub__summary-facts">
                {{#each this.facts as |fact|}}
                  <span class="fomio-me-hub__summary-fact">
                    <span class="fomio-me-hub__summary-fact-icon" aria-hidden="true">{{icon
                        fact.icon
                      }}</span>
                    <span class="fomio-me-hub__summary-fact-copy">{{fact.value}}</span>
                  </span>
                {{/each}}
              </FomioMetaRow>
            {{/if}}

            {{#if this.bioHtml}}
              <span class="fomio-me-hub__summary-bio">
                <HtmlWithLinks>
                  {{this.bioHtml}}
                </HtmlWithLinks>
              </span>
            {{/if}}

            {{#if this.stats.length}}
              <FomioMetaRow @extraClass="fomio-me-hub__summary-stats" @emphasized={{true}}>
                {{#each this.stats as |stat|}}
                  <span class="fomio-me-hub__summary-stat">
                    <span class="fomio-me-hub__summary-stat-icon" aria-hidden="true">{{icon
                        stat.icon
                      }}</span>
                    <span class="fomio-me-hub__summary-stat-copy">{{stat.value}}
                      {{stat.label}}</span>
                  </span>
                {{/each}}
              </FomioMetaRow>
            {{/if}}
          </span>
        </div>

        {{#if this.hasHeaderControls}}
          <div class="fomio-me-hub__summary-actions">
            {{#if this.adminFirst}}
              {{#if this.showAdminAction}}
                <FomioButton
                  @href={{this.args.adminHref}}
                  @variant="secondary"
                  @size="sm"
                  @leadingIcon="wrench"
                  @extraClass="fomio-me-hub__summary-action"
                >
                  <span class="fomio-me-hub__summary-action-label">{{this.args.adminLabel}}</span>
                </FomioButton>
              {{/if}}
            {{/if}}

            {{#if this.showExpand}}
              <FomioButton
                @variant="secondary"
                @size="sm"
                @iconOnly={{this.useHubStyleExpandToggle}}
                @extraClass={{this.expandButtonClass}}
                aria-controls={{this.detailsPanelId}}
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
              </FomioButton>
            {{/if}}

            {{#unless this.adminFirst}}
              {{#if this.showAdminAction}}
                <FomioButton
                  @href={{this.args.adminHref}}
                  @variant="secondary"
                  @size="sm"
                  @leadingIcon="wrench"
                  @extraClass="fomio-me-hub__summary-action"
                >
                  <span class="fomio-me-hub__summary-action-label">{{this.args.adminLabel}}</span>
                </FomioButton>
              {{/if}}
            {{/unless}}
          </div>
        {{/if}}
      </div>

      {{#if this.showDetails}}
        <div class="fomio-me-hub__details is-open" id={{this.detailsPanelId}}>
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
