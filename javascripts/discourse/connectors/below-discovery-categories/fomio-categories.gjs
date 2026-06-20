import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioCard from "../../components/shared/fomio-card";
import FomioSegmentedControl from "../../components/shared/fomio-segmented-control";
import { buildFomioHubCatalog } from "../../lib/fomio-hub-catalog";

function fmtK(n) {
  if (!n) return "0";
  return n >= 1000 ? (n / 1000).toFixed(1).replace(/\.0$/, "") + "k" : String(n);
}

export default class FomioCategories extends Component {
  @service site;

  @tracked view = "grid";

  constructor(owner, args) {
    super(owner, args);

    if (typeof document !== "undefined") {
      document.body?.classList.add("fomio-hubs-active");
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);

    if (typeof document !== "undefined") {
      document.body?.classList.remove("fomio-hubs-active");
    }
  }

  get hubCatalog() {
    return buildFomioHubCatalog([
      this.site?.categories,
      this.site?.categoryList?.categories,
      this.site?.categoriesList,
      this.site?.site?.categories,
      this.args?.outletArgs?.site?.categories,
      this.args?.outletArgs?.categoryList?.categories,
    ]);
  }

  get hubs() {
    return this.hubCatalog.allTopLevelHubs;
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

  get hubsWithTerets() {
    const all = this.hubCatalog.categories;
    return this.hubs
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

  get overviewLeadHubs() {
    return this.hubsWithTerets.slice(0, 3);
  }

  get titleLabel()        { return i18n(themePrefix("hubs_index.title")); }
  get descriptionLabel()  { return i18n(themePrefix("hubs_index.description")); }
  get overviewLabel()     { return i18n(themePrefix("hubs_index.overview_copy")); }
  get selectHintLabel()   { return i18n(themePrefix("hubs_index.select_hint")); }
  get overviewListLabel() { return i18n(themePrefix("hubs_index.overview_list_title")); }
  get overviewSignalLabel() { return i18n(themePrefix("hubs_index.overview_signal")); }
  get viewGridLabel()     { return i18n(themePrefix("hubs_index.view_grid")); }
  get viewListLabel()     { return i18n(themePrefix("hubs_index.view_list")); }
  get bytesLabel()        { return i18n(themePrefix("hubs_index.bytes_label")); }
  get viewOptions() {
    return [
      {
        id: "grid",
        phIcon: "fomio-ph-table",
        ariaLabel: this.viewGridLabel,
        isActive: this.view === "grid",
      },
      {
        id: "list",
        phIcon: "fomio-ph-list-bullets",
        ariaLabel: this.viewListLabel,
        isActive: this.view === "list",
      },
    ];
  }

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
          <FomioSegmentedControl
            @wrapperClass="fomio-hubs__view-toggle"
            @buttonClass="fomio-hubs__view-btn"
            @ariaLabel={{this.viewGridLabel}}
            @options={{this.viewOptions}}
            @onSelect={{this.setView}}
          />
        {{/unless}}
      </div>

      {{#if this.isMasterPaneActive}}
        <section class="fomio-hubs__overview" aria-label={{this.titleLabel}}>
          <div class="fomio-hubs__overview-intro">
            <p class="fomio-hubs__overview-copy">{{this.overviewLabel}}</p>
            <p class="fomio-hubs__overview-hint">{{this.selectHintLabel}}</p>
          </div>

          <div class="fomio-hubs__overview-band">
            <div class="fomio-hubs__overview-stat-card">
              <span class="fomio-hubs__overview-stat-label">{{this.overviewSignalLabel}}</span>
              <span class="fomio-hubs__overview-stat-value">{{this.statLine}}</span>
            </div>

            <div class="fomio-hubs__overview-lead">
              <div class="fomio-hubs__overview-lead-title">{{this.overviewListLabel}}</div>
              <div class="fomio-hubs__overview-lead-list">
                {{#each this.overviewLeadHubs as |entry|}}
                  <a
                    href="/c/{{entry.hub.slug}}/{{entry.hub.id}}"
                    class="fomio-hubs__overview-lead-item"
                  >
                    <div class="fomio-hubs__overview-lead-main">
                      <span
                        class="fomio-hub-swatch fomio-hubs__overview-swatch"
                        style="background: #{{entry.hub.color}}; color: #{{entry.hub.text_color}}"
                        aria-hidden="true"
                      >{{entry.letter}}</span>
                      <span class="fomio-hubs__overview-lead-name">{{entry.hub.name}}</span>
                    </div>
                    <span class="fomio-hubs__overview-lead-meta">{{entry.bytesLabel}} {{this.bytesLabel}}</span>
                  </a>
                {{/each}}
              </div>
            </div>
          </div>
        </section>
      {{/if}}

      {{! ── Grid ────────────────────────────────────────────── }}
      {{#if (eq this.view "grid")}}
        <div class="fomio-hubs__grid">
          {{#each this.hubsWithTerets as |entry|}}
            {{#let entry.hub entry.terets as |hub terets|}}
              <FomioCard
                @href="/c/{{hub.slug}}/{{hub.id}}"
                @interactive={{true}}
                @extraClass="fomio-hub-card"
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
              </FomioCard>
            {{/let}}
          {{/each}}
        </div>

      {{! ── List ────────────────────────────────────────────── }}
      {{else}}
        <div class="fomio-hubs__list">
          {{#each this.hubsWithTerets as |entry|}}
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

    </div>
  </template>
}
