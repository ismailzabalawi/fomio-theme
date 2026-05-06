import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import icon from "discourse/helpers/d-icon";

function fmtK(n) {
  if (!n) return "0";
  return n >= 1000 ? (n / 1000).toFixed(1).replace(/\.0$/, "") + "k" : String(n);
}

export default class FomioHubChrome extends Component {
  @service site;
  @service router;

  // The category passed from the outlet — may be a Hub or a Teret.
  get category() {
    return this.args.category ?? null;
  }

  // Resolve the top-level Hub regardless of whether we're on a Hub or Teret page.
  get hub() {
    const cat = this.category;
    if (!cat) return null;
    if (!cat.parent_category_id) return cat;
    return (this.site.categories || []).find((c) => c.id === cat.parent_category_id) ?? null;
  }

  // The active Teret when on a sub-category page, null when on the Hub root.
  get activeTeret() {
    const cat = this.category;
    return cat?.parent_category_id ? cat : null;
  }

  get terets() {
    if (!this.hub) return [];
    return (this.site.categories || []).filter(
      (c) => c.parent_category_id === this.hub.id
    );
  }

  // Only render on Hub/Teret discovery pages, not on the /categories index (category=null).
  get shouldRender() {
    return !!this.hub;
  }

  get swatchLetter() {
    return this.hub?.name?.[0] ?? "";
  }

  get bytesFormatted()   { return fmtK(this.hub?.topic_count  || 0); }
  get repliesFormatted() { return fmtK(this.hub?.post_count   || 0); }

  get currentFilter() {
    const url = (this.router.currentURL || "").split("?")[0];
    if (url.includes("/l/top")) return "top";
    if (url.includes("/l/new")) return "new";
    return "latest";
  }

  get filters() {
    const hub = this.hub;
    if (!hub) return [];
    return [
      {
        key: "latest",
        label: i18n(themePrefix("hub_page.filter_latest")),
        url: `/c/${hub.slug}/${hub.id}`,
        isActive: this.currentFilter === "latest",
      },
      {
        key: "top",
        label: i18n(themePrefix("hub_page.filter_top")),
        url: `/c/${hub.slug}/${hub.id}/l/top`,
        isActive: this.currentFilter === "top",
      },
      {
        key: "new",
        label: i18n(themePrefix("hub_page.filter_new")),
        url: `/c/${hub.slug}/${hub.id}/l/new`,
        isActive: this.currentFilter === "new",
      },
    ];
  }

  get teretTabs() {
    const hub = this.hub;
    if (!hub || !this.terets.length) return [];
    return [
      {
        id: null,
        name: i18n(themePrefix("hub_page.teret_all")),
        url: `/c/${hub.slug}/${hub.id}`,
        isActive: !this.activeTeret,
        count: null,
      },
      ...this.terets.map((t) => ({
        id: t.id,
        name: t.name,
        url: `/c/${hub.slug}/${t.slug}/${t.id}`,
        isActive: this.activeTeret?.id === t.id,
        count: fmtK(t.topic_count || 0),
      })),
    ];
  }

  get breadcrumbLabel()   { return i18n(themePrefix("hub_page.breadcrumb_hubs")); }
  get bytesLabel()        { return i18n(themePrefix("hub_page.bytes_label")); }
  get repliesLabel()      { return i18n(themePrefix("hub_page.replies_label")); }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-hub-chrome">

        {{! ── Breadcrumb ── }}
        <nav class="fomio-hub-chrome__breadcrumb" aria-label="Breadcrumb">
          <a href="/categories" class="fomio-hub-chrome__crumb-link">{{this.breadcrumbLabel}}</a>
          <span class="fomio-hub-chrome__crumb-sep" aria-hidden="true">{{icon "angle-right"}}</span>
          <span class="fomio-hub-chrome__crumb-current">{{this.hub.name}}</span>
        </nav>

        {{! ── Hero ── }}
        <div class="fomio-hub-chrome__hero">
          <div
            class="fomio-hub-chrome__swatch"
            style="background: #{{this.hub.color}}; color: #{{this.hub.text_color}}; box-shadow: 0 2px 8px #{{this.hub.color}}55"
            aria-hidden="true"
          >{{this.swatchLetter}}</div>

          <div class="fomio-hub-chrome__hero-body">
            <h1 class="fomio-hub-chrome__name">{{this.hub.name}}</h1>
            {{#if this.hub.description_text}}
              <p class="fomio-hub-chrome__desc">{{this.hub.description_text}}</p>
            {{/if}}
            <div class="fomio-hub-chrome__stats">
              <span class="fomio-hub-chrome__stat">
                <strong>{{this.bytesFormatted}}</strong>
                <span>{{this.bytesLabel}}</span>
              </span>
              <span class="fomio-hub-chrome__stat-sep" aria-hidden="true">·</span>
              <span class="fomio-hub-chrome__stat">
                <strong>{{this.repliesFormatted}}</strong>
                <span>{{this.repliesLabel}}</span>
              </span>
            </div>
          </div>
        </div>

        {{! ── Teret tabs ── }}
        {{#if this.teretTabs.length}}
          <div class="fomio-hub-chrome__teret-tabs" role="tablist" aria-label="Terets">
            {{#each this.teretTabs as |tab|}}
              <a
                href={{tab.url}}
                class="fomio-hub-chrome__tab {{if tab.isActive 'is-active'}}"
                role="tab"
                aria-selected={{if tab.isActive "true" "false"}}
              >
                {{tab.name}}
                {{#if tab.count}}
                  <span class="fomio-hub-chrome__tab-count">{{tab.count}}</span>
                {{/if}}
              </a>
            {{/each}}
          </div>
        {{/if}}

        {{! ── Filter bar ── }}
        <div class="fomio-hub-chrome__filters" role="tablist" aria-label="Sort">
          {{#each this.filters as |f|}}
            <a
              href={{f.url}}
              class="fomio-hub-chrome__filter {{if f.isActive 'is-active'}}"
              role="tab"
              aria-selected={{if f.isActive "true" "false"}}
            >{{f.label}}</a>
          {{/each}}
        </div>

      </div>
    {{/if}}
  </template>
}
