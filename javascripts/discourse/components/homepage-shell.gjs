import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings } from "virtual:theme";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

const HOMEPAGE_PATHS = new Set([
  "/",
  "/latest",
  "/new",
  "/unread",
  "/top",
  "/categories",
]);

export default class HomepageShell extends Component {
  @service router;

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return HOMEPAGE_PATHS.has(this.currentPath);
  }

  get appUrl() {
    return settings.fomio_app_url?.trim();
  }

  get hasAppUrl() {
    return Boolean(this.appUrl);
  }

  get latestUrl() {
    return this.router.urlFor("discovery.latest");
  }

  get categoriesUrl() {
    return this.router.urlFor("discovery.categories");
  }

  get eyebrow() {
    return i18n(themePrefix("homepage_shell.eyebrow"));
  }

  get title() {
    return i18n(themePrefix("homepage_shell.title"));
  }

  get dek() {
    return i18n(themePrefix("homepage_shell.dek"));
  }

  get primaryAction() {
    return i18n(themePrefix("homepage_shell.primary_action"));
  }

  get secondaryAction() {
    return i18n(themePrefix("homepage_shell.secondary_action"));
  }

  get leadLabel() {
    return i18n(themePrefix("homepage_shell.lead_label"));
  }

  get leadTitle() {
    return i18n(themePrefix("homepage_shell.lead_title"));
  }

  get leadCopy() {
    return i18n(themePrefix("homepage_shell.lead_copy"));
  }

  get signalOne() {
    return i18n(themePrefix("homepage_shell.signal_one"));
  }

  get signalTwo() {
    return i18n(themePrefix("homepage_shell.signal_two"));
  }

  get signalThree() {
    return i18n(themePrefix("homepage_shell.signal_three"));
  }

  get latestLabel() {
    return i18n(themePrefix("homepage_shell.latest_label"));
  }

  get latestCopy() {
    return i18n(themePrefix("homepage_shell.latest_copy"));
  }

  get handoffLabel() {
    return i18n(themePrefix("homepage_shell.handoff_label"));
  }

  get handoffCopy() {
    return i18n(themePrefix("homepage_shell.handoff_copy"));
  }

  get handoffAction() {
    return i18n(themePrefix("homepage_shell.handoff_action"));
  }

  <template>
    {{#if this.shouldRender}}
      <section class="fomio-home-shell">
        <div class="fomio-home-shell__hero">
          <div class="fomio-home-shell__intro">
            <p class="fomio-home-shell__eyebrow">{{this.eyebrow}}</p>
            <h1 class="fomio-home-shell__title">{{this.title}}</h1>
            <p class="fomio-home-shell__dek">{{this.dek}}</p>
            <div class="fomio-home-shell__actions">
              <a class="fomio-home-shell__primary-link" href={{this.latestUrl}}>
                {{this.primaryAction}}
              </a>
              <a class="fomio-home-shell__secondary-link" href={{this.categoriesUrl}}>
                {{this.secondaryAction}}
              </a>
            </div>
          </div>

          <aside class="fomio-home-shell__lead-card">
            <p class="fomio-home-shell__card-label">{{this.leadLabel}}</p>
            <h2 class="fomio-home-shell__card-title">{{this.leadTitle}}</h2>
            <p class="fomio-home-shell__card-copy">{{this.leadCopy}}</p>
            <ul class="fomio-home-shell__signals" role="list">
              <li>{{this.signalOne}}</li>
              <li>{{this.signalTwo}}</li>
              <li>{{this.signalThree}}</li>
            </ul>
          </aside>
        </div>

        <div class="fomio-home-shell__supporting">
          <section class="fomio-home-shell__section">
            <p class="fomio-home-shell__section-label">{{this.latestLabel}}</p>
            <p class="fomio-home-shell__section-copy">{{this.latestCopy}}</p>
          </section>

          <section class="fomio-home-shell__section fomio-home-shell__section--handoff">
            <p class="fomio-home-shell__section-label">{{this.handoffLabel}}</p>
            <p class="fomio-home-shell__section-copy">{{this.handoffCopy}}</p>

            {{#if this.hasAppUrl}}
              <a
                class="fomio-home-shell__app-link"
                href={{this.appUrl}}
                target="_blank"
                rel="noopener noreferrer"
              >
                {{this.handoffAction}}
              </a>
            {{/if}}
          </section>
        </div>
      </section>
    {{/if}}
  </template>
}
