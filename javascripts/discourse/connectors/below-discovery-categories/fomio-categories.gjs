import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

function fmtK(n) {
  if (!n) return "0";
  return n >= 1000 ? (n / 1000).toFixed(1).replace(/\.0$/, "") + "k" : String(n);
}

export default class FomioCategories extends Component {
  @service site;

  @tracked view = "grid";
  @tracked searchQuery = "";

  get hubs() {
    return (this.site.categories || []).filter((c) => !c.parent_category_id);
  }

  get totalBytes() {
    return this.hubs.reduce((s, c) => s + (c.topic_count || 0), 0);
  }

  get statLine() {
    return i18n(themePrefix("hubs_index.stat"), {
      count: this.hubs.length,
      bytes: fmtK(this.totalBytes),
    });
  }

  get filteredHubsWithTerets() {
    const q = this.searchQuery.toLowerCase().trim();
    const all = this.site.categories || [];
    return this.hubs
      .filter((hub) => {
        if (!q) return true;
        return (
          hub.name.toLowerCase().includes(q) ||
          (hub.description_text || "").toLowerCase().includes(q)
        );
      })
      .map((hub) => {
        const terets = all.filter((c) => c.parent_category_id === hub.id);
        return {
          hub,
          terets,
          letter: hub.name ? hub.name[0] : "",
          bytesLabel: fmtK(hub.topic_count),
          teretNames: terets.map((t) => t.name).join(" · "),
        };
      });
  }

  get titleLabel()        { return i18n(themePrefix("hubs_index.title")); }
  get descriptionLabel()  { return i18n(themePrefix("hubs_index.description")); }
  get overviewLabel()     { return i18n(themePrefix("hubs_index.overview_copy")); }
  get selectHintLabel()   { return i18n(themePrefix("hubs_index.select_hint")); }
  get searchPlaceholder() { return i18n(themePrefix("hubs_index.search_placeholder")); }
  get viewGridLabel()     { return i18n(themePrefix("hubs_index.view_grid")); }
  get viewListLabel()     { return i18n(themePrefix("hubs_index.view_list")); }
  get bytesLabel()        { return i18n(themePrefix("hubs_index.bytes_label")); }

  get isMasterPaneActive() {
    if (typeof document === "undefined") {
      return false;
    }
    const classes = document.body?.classList;
    const hasDesktopMasterSurface =
      classes?.contains("fomio-surface-expanded") ||
      classes?.contains("fomio-surface-compact-desktop");
    return (
      Boolean(hasDesktopMasterSurface) &&
      classes?.contains("fomio-sidebar-active") &&
      !classes?.contains("fomio-auth-mode") &&
      Boolean(document.querySelector(".fomio-master-pane"))
    );
  }

  @action setView(v) { this.view = v; }
  @action updateSearch(e) { this.searchQuery = e.target.value; }

  <template>
    <div class="fomio-hubs">

      {{! ── Page header ─────────────────────────────────────── }}
      <div class="fomio-hubs__header">
        <div class="fomio-hubs__heading">
          <h1 class="fomio-hubs__title">{{this.titleLabel}}</h1>
          <p class="fomio-hubs__description">{{this.descriptionLabel}}</p>
          <p class="fomio-hubs__stat">{{this.statLine}}</p>
        </div>
        {{#unless this.isMasterPaneActive}}
          <div class="fomio-hubs__view-toggle">
            <button
              type="button"
              class="fomio-hubs__view-btn {{if (eq this.view 'grid') 'is-active'}}"
              aria-label={{this.viewGridLabel}}
              aria-pressed={{if (eq this.view "grid") "true" "false"}}
              {{on "click" (fn this.setView "grid")}}
            >{{icon "table-cells"}}</button>
            <button
              type="button"
              class="fomio-hubs__view-btn {{if (eq this.view 'list') 'is-active'}}"
              aria-label={{this.viewListLabel}}
              aria-pressed={{if (eq this.view "list") "true" "false"}}
              {{on "click" (fn this.setView "list")}}
            >{{icon "list"}}</button>
          </div>
        {{/unless}}
      </div>

      {{#if this.isMasterPaneActive}}
        <section class="fomio-hubs__overview" aria-label={{this.titleLabel}}>
          <p class="fomio-hubs__overview-copy">{{this.overviewLabel}}</p>
          <p class="fomio-hubs__overview-hint">{{this.selectHintLabel}}</p>
        </section>
      {{else}}
        {{! ── Search ──────────────────────────────────────────── }}
        <div class="fomio-hubs__search" {{on "input" this.updateSearch}}>
          <span class="fomio-hubs__search-icon">{{icon "magnifying-glass"}}</span>
          <input
            type="search"
            class="fomio-hubs__search-input"
            placeholder={{this.searchPlaceholder}}
          />
        </div>

        {{! ── Grid ────────────────────────────────────────────── }}
        {{#if (eq this.view "grid")}}
          <div class="fomio-hubs__grid">
            {{#each this.filteredHubsWithTerets as |entry|}}
              {{#let entry.hub entry.terets as |hub terets|}}
                <a
                  href="/c/{{hub.slug}}/{{hub.id}}"
                  class="fomio-hub-card"
                >
                  <div class="fomio-hub-card__top">
                    <div
                      class="fomio-hub-swatch"
                      style="background: #{{hub.color}}; color: #{{hub.text_color}}"
                      aria-hidden="true"
                    >{{entry.letter}}</div>
                    <div class="fomio-hub-card__identity">
                      <div class="fomio-hub-card__name">{{hub.name}}</div>
                      <div class="fomio-hub-card__count">{{entry.bytesLabel}} {{this.bytesLabel}}</div>
                    </div>
                  </div>
                  {{#if hub.description_text}}
                    <p class="fomio-hub-card__desc">{{hub.description_text}}</p>
                  {{/if}}
                  {{#if terets.length}}
                    <div class="fomio-hub-card__terets">
                      {{#each terets as |teret|}}
                        <span class="fomio-hub-card__teret-pill">{{teret.name}}</span>
                      {{/each}}
                    </div>
                  {{/if}}
                </a>
              {{/let}}
            {{/each}}
          </div>

        {{! ── List ────────────────────────────────────────────── }}
        {{else}}
          <div class="fomio-hubs__list">
            {{#each this.filteredHubsWithTerets as |entry|}}
              {{#let entry.hub entry.terets as |hub terets|}}
                <a
                  href="/c/{{hub.slug}}/{{hub.id}}"
                  class="fomio-hub-row"
                >
                  <div
                    class="fomio-hub-swatch fomio-hub-swatch--lg"
                    style="background: #{{hub.color}}; color: #{{hub.text_color}}"
                    aria-hidden="true"
                  >{{entry.letter}}</div>
                  <div class="fomio-hub-row__body">
                    <div class="fomio-hub-row__top">
                      <span class="fomio-hub-row__name">{{hub.name}}</span>
                      {{#if entry.teretNames}}
                        <span class="fomio-hub-row__terets">{{entry.teretNames}}</span>
                      {{/if}}
                    </div>
                    {{#if hub.description_text}}
                      <p class="fomio-hub-row__desc">{{hub.description_text}}</p>
                    {{/if}}
                  </div>
                  <div class="fomio-hub-row__meta">
                    <span class="fomio-hub-row__count">{{entry.bytesLabel}}</span>
                    <span class="fomio-hub-row__label">{{this.bytesLabel}}</span>
                  </div>
                  <span class="fomio-hub-row__chevron" aria-hidden="true">{{icon "angle-right"}}</span>
                </a>
              {{/let}}
            {{/each}}
          </div>
        {{/if}}
      {{/if}}

    </div>
  </template>
}
