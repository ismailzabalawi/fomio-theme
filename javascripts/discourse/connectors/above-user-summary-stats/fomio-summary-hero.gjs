// Editorial hero for the profile Summary detail surface, rendered through
// Discourse's `above-user-summary-stats` outlet (outletArgs: { model, user }).
// Mirrors the prototype's ProfileHeroEditorial (claude.ai/design — Fomio User
// Profile): avatar + serif name, an eyebrow (title / admin), @handle · location
// · website, a self-only "Edit profile" action, serif-italic bio, four serif
// stat blocks (bytes / replies / received / given mapped from
// UserSummarySerializer), and an "On Fomio since … · groups" footer.
// Display-only; reads from outletArgs + the currentUser service. No fetch.
import Component from "@glimmer/component";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioAvatar from "../../components/shared/fomio-avatar";
import FomioMetaRow from "../../components/shared/fomio-meta-row";
import { profileSummaryStats } from "../../lib/fomio-profile-summary-fields";

const MAX_GROUP_PILLS = 3;

export default class FomioSummaryHero extends Component {
  @service currentUser;

  get user() {
    return this.args.outletArgs?.user;
  }

  get model() {
    return this.args.outletArgs?.model;
  }

  get displayName() {
    const user = this.user;
    return (user?.name && String(user.name).trim()) || user?.username || "";
  }

  get handle() {
    const username = this.user?.username;
    return username ? `@${username}` : null;
  }

  get isAdmin() {
    return Boolean(this.user?.admin);
  }

  // Eyebrow = the user's title, falling back to an "Admin" marker for staff.
  get eyebrow() {
    const title = this.user?.title;
    if (title && String(title).trim()) {
      return String(title).trim();
    }
    return this.isAdmin ? i18n(themePrefix("profile_hero.admin")) : null;
  }

  get location() {
    const location = this.user?.location;
    return (location && String(location).trim()) || null;
  }

  get websiteName() {
    const name = this.user?.website_name;
    return (name && String(name).trim()) || null;
  }

  get websiteUrl() {
    return this.user?.website || null;
  }

  get bioHtml() {
    const bio = this.user?.bio_cooked;
    return bio && String(bio).trim() ? htmlSafe(bio) : null;
  }

  get isSelf() {
    const mine = this.currentUser?.username;
    const theirs = this.user?.username;
    return Boolean(
      mine && theirs && String(mine).toLowerCase() === String(theirs).toLowerCase()
    );
  }

  // Self-only "Edit profile"; the "Message" action for other users is v2
  // (Messages are out of v1 scope — see user-profile-questionnaire.md §1.3).
  get editProfileHref() {
    if (!this.isSelf || !this.user?.username) {
      return null;
    }
    return `/u/${this.user.username}/preferences/profile`;
  }

  get joinedLabel() {
    const createdAt = this.user?.created_at;
    if (!createdAt) {
      return null;
    }

    const date = new Date(createdAt);
    if (Number.isNaN(date.getTime())) {
      return null;
    }

    const formatted = new Intl.DateTimeFormat(undefined, {
      month: "long",
      year: "numeric",
    }).format(date);

    return i18n(themePrefix("summary_page.joined"), { date: formatted });
  }

  // Visible groups: drop automatic (trust-level / everyone) groups, prefer the
  // human-readable full name, cap the count so the footer stays calm.
  get groups() {
    const groups = this.user?.groups;
    if (!Array.isArray(groups)) {
      return [];
    }
    return groups
      .filter((group) => group && !group.automatic)
      .map((group) => group.full_name || group.name)
      .filter(Boolean)
      .slice(0, MAX_GROUP_PILLS);
  }

  get stats() {
    return profileSummaryStats(this.model);
  }

  statLabel = (stat) => {
    const key = themePrefix(`profile_hero.${stat.key}`);
    return stat.pluralize ? i18n(key, { count: stat.count }) : i18n(key);
  };

  <template>
    <header class="fomio-summary-hero">
      <div class="fomio-summary-hero__top">
        <FomioAvatar @user={{this.user}} @size="xl" />

        <div class="fomio-summary-hero__identity-text">
          {{#if this.eyebrow}}
            <span
              class="fomio-summary-hero__eyebrow {{if this.isAdmin 'is-admin'}}"
            >{{this.eyebrow}}</span>
          {{/if}}

          <h2 class="fomio-summary-hero__title">{{this.displayName}}</h2>

          <div class="fomio-summary-hero__meta">
            {{#if this.handle}}
              <span class="fomio-summary-hero__handle">{{this.handle}}</span>
            {{/if}}
            {{#if this.location}}
              <span class="fomio-summary-hero__dot">·</span>
              <span>{{this.location}}</span>
            {{/if}}
            {{#if this.websiteName}}
              <span class="fomio-summary-hero__dot">·</span>
              <a
                class="fomio-summary-hero__website"
                href={{this.websiteUrl}}
                rel="nofollow ugc noopener"
              >{{this.websiteName}}</a>
            {{/if}}
          </div>
        </div>

        {{#if this.editProfileHref}}
          <a class="fomio-summary-hero__action" href={{this.editProfileHref}}>
            {{i18n (themePrefix "profile_hero.edit_profile")}}
          </a>
        {{/if}}
      </div>

      {{#if this.bioHtml}}
        <p class="fomio-summary-hero__bio">{{this.bioHtml}}</p>
      {{else if this.displayName}}
        <p class="fomio-summary-hero__deck">
          {{i18n (themePrefix "summary_page.deck") name=this.displayName}}
        </p>
      {{/if}}

      <FomioMetaRow
        @emphasized={{true}}
        class="fomio-summary-hero__stats"
        role="group"
        aria-label={{i18n (themePrefix "profile_hero.stats_aria")}}
      >
        {{#each this.stats as |stat|}}
          <span class="fomio-summary-hero__stat">
            <span class="fomio-summary-hero__stat-value">{{stat.formatted}}</span>
            <span class="fomio-summary-hero__stat-label">{{this.statLabel stat}}</span>
          </span>
        {{/each}}
      </FomioMetaRow>

      {{#if this.joinedLabel}}
        <div class="fomio-summary-hero__footer">
          <span>{{this.joinedLabel}}</span>
          {{#if this.groups.length}}
            <span class="fomio-summary-hero__dot">·</span>
            {{#each this.groups as |group|}}
              <span class="fomio-summary-hero__group">{{group}}</span>
            {{/each}}
          {{/if}}
        </div>
      {{/if}}
    </header>
  </template>
}
