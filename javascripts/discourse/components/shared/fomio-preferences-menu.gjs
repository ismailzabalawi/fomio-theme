import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioList from "./fomio-list";
import FomioListItem from "./fomio-list-item";
import FomioButton from "./fomio-button";
import {
  FOMIO_PREFERENCES_MENU_CLASS,
  FOMIO_PREFERENCES_MENU_CLOSE_EVENT,
  FOMIO_PREFERENCES_MENU_OPEN_EVENT,
  publishFomioPreferencesMenuState,
} from "../../lib/fomio-preferences-menu";
import { FOMIO_PREFERENCES_SECTIONS } from "../../lib/fomio-preferences-sections";

function isPreferencesPath(path) {
  return /(?:^\/my\/preferences(?:\/|$)|^\/u\/[^/]+\/preferences(?:\/|$))/i.test(
    path || ""
  );
}

export default class FomioPreferencesMenu extends Component {
  DESKTOP_GAP = 12;
  DESKTOP_MARGIN = 16;
  DESKTOP_WIDTH = 320;

  @service currentUser;
  @service router;

  @tracked isOpen = false;
  @tracked source = "desktop";
  @tracked anchorRect = null;
  @tracked measuredHeight = 0;

  constructor(owner, args) {
    super(owner, args);

    this._handleOpen = (event) => {
      if (!this.currentUser) {
        return;
      }

      this.source = event?.detail?.source === "mobile" ? "mobile" : "desktop";
      this.anchorRect = event?.detail?.anchorRect ?? null;
      this.isOpen = true;
      document.body?.classList.add(FOMIO_PREFERENCES_MENU_CLASS);
      publishFomioPreferencesMenuState(true, this.source);
    };

    this._handleClose = () => this.close();
    this._onRouteDidChange = () => {
      if (!this.isOpen) {
        return;
      }

      const path = (this.router.currentURL || "").split("?")[0];
      if (!isPreferencesPath(path)) {
        this.close();
      }
    };

    if (typeof window !== "undefined") {
      window.addEventListener(
        FOMIO_PREFERENCES_MENU_OPEN_EVENT,
        this._handleOpen
      );
      window.addEventListener(
        FOMIO_PREFERENCES_MENU_CLOSE_EVENT,
        this._handleClose
      );
    }

    this.router.on("routeDidChange", this._onRouteDidChange);
  }

  willDestroy() {
    super.willDestroy(...arguments);

    if (typeof window !== "undefined") {
      window.removeEventListener(
        FOMIO_PREFERENCES_MENU_OPEN_EVENT,
        this._handleOpen
      );
      window.removeEventListener(
        FOMIO_PREFERENCES_MENU_CLOSE_EVENT,
        this._handleClose
      );
    }

    this.router.off("routeDidChange", this._onRouteDidChange);
    this._panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_PREFERENCES_MENU_CLASS);
    publishFomioPreferencesMenuState(false, this.source);
  }

  get shouldRender() {
    return Boolean(this.currentUser && this.isOpen);
  }

  get panelClass() {
    return `fomio-preferences-menu fomio-preferences-menu--${this.source}`;
  }

  get panelStyle() {
    if (
      this.source !== "desktop" ||
      !this.anchorRect ||
      typeof window === "undefined"
    ) {
      return null;
    }

    const sidebar = document.querySelector(".fomio-sidebar");
    const sidebarRect = sidebar ? sidebar.getBoundingClientRect() : null;
    const sidebarRight = sidebarRect ? sidebarRect.right : null;
    const preferredLeft =
      sidebarRight != null
        ? sidebarRight + this.DESKTOP_GAP
        : this.anchorRect.right + this.DESKTOP_GAP;
    const maxWidth = Math.min(
      this.DESKTOP_WIDTH,
      Math.max(300, window.innerWidth - preferredLeft - this.DESKTOP_MARGIN)
    );
    const left = Math.max(
      this.DESKTOP_MARGIN,
      Math.min(
        preferredLeft,
        window.innerWidth - maxWidth - this.DESKTOP_MARGIN
      )
    );
    return `top:${this.DESKTOP_MARGIN}px;bottom:${this.DESKTOP_MARGIN}px;left:${Math.round(left)}px;width:${Math.round(
      maxWidth
    )}px;`;
  }

  get title() {
    return i18n(themePrefix("preferences_overlay.title"));
  }

  get ariaLabel() {
    return i18n(themePrefix("preferences_overlay.aria_label"));
  }

  get closeLabel() {
    return i18n(themePrefix("preferences_overlay.close"));
  }

  get sections() {
    return FOMIO_PREFERENCES_SECTIONS.map((section) => ({
      ...section,
      label: i18n(section.labelKey),
      subtitle: i18n(themePrefix(section.subtitleKey)),
      isActive: this.isSectionActive(section.key),
    }));
  }

  isSectionActive(key) {
    const path = (this.router.currentURL || "").split("?")[0].toLowerCase();
    if (key === "account") {
      return (
        path === "/my/preferences" ||
        /\/preferences\/account(?:\/|$)/.test(path)
      );
    }

    return path.includes(`/preferences/${key}`);
  }

  @action
  close() {
    this.isOpen = false;
    this.anchorRect = null;
    this.measuredHeight = 0;
    this._panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_PREFERENCES_MENU_CLASS);
    publishFomioPreferencesMenuState(false, this.source);
  }

  @action
  closeFromBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  @action
  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.close();
    }
  }

  @action
  setupPanel(element) {
    element.focus();

    const measure = () => {
      this.measuredHeight = Math.round(element.getBoundingClientRect().height);
    };

    measure();
    this._panelResizeObserver?.disconnect();
    if (typeof ResizeObserver !== "undefined") {
      this._panelResizeObserver = new ResizeObserver(() => measure());
      this._panelResizeObserver.observe(element);
    }
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="fomio-preferences-menu-shell"
        role="presentation"
        {{on "click" this.closeFromBackdrop}}
      >
        <div
          class={{this.panelClass}}
          style={{this.panelStyle}}
          role="dialog"
          aria-modal="true"
          aria-label={{this.ariaLabel}}
          tabindex="-1"
          {{didInsert this.setupPanel}}
          {{on "keydown" this.handleKeydown}}
        >
          <header class="fomio-prefs-menu__header">
            <span class="fomio-prefs-menu__title">{{this.title}}</span>
            <FomioButton
              @variant="ghost"
              @size="sm"
              @iconOnly={{true}}
              @leadingIcon="xmark"
              @extraClass="fomio-prefs-menu__close"
              aria-label={{this.closeLabel}}
              {{on "click" this.close}}
            />
          </header>

          <FomioList @extraClass="fomio-prefs-menu__list">
            {{#each this.sections as |section|}}
              <FomioListItem
                @href={{section.href}}
                @leadingIcon={{section.icon}}
                @title={{section.label}}
                @subtitle={{section.subtitle}}
                @trailingIcon="angle-right"
                @isActive={{section.isActive}}
                @extraClass="fomio-prefs-menu__item"
              />
            {{/each}}
          </FomioList>
        </div>
      </div>
    {{/if}}
  </template>
}
