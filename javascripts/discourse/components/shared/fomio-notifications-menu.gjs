import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import UserMenu from "discourse/components/user-menu/menu";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import {
  FOMIO_NOTIFICATIONS_MENU_CLASS,
  FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
  FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
  publishFomioNotificationsMenuState,
} from "../../lib/fomio-notifications-menu";

export default class FomioNotificationsMenu extends Component {
  DESKTOP_GAP = 12;
  DESKTOP_MARGIN = 16;
  DESKTOP_WIDTH = 368;
  DESKTOP_MAX_HEIGHT = 704;

  @service currentUser;
  @service router;

  @tracked isOpen = false;
  @tracked source = "desktop";
  @tracked anchorRect = null;
  @tracked measuredHeight = 0;
  @tracked measuredFooterHeight = 0;

  constructor(owner, args) {
    super(owner, args);

    this.#handleOpen = (event) => {
      if (!this.currentUser) {
        return;
      }

      const nextSource =
        event?.detail?.source === "mobile" ? "mobile" : "desktop";
      if (this.isOpen && this.source === nextSource) {
        this.close();
        return;
      }

      this.source = nextSource;
      this.anchorRect = event?.detail?.anchorRect ?? null;
      this.isOpen = true;
      document.body?.classList.add(FOMIO_NOTIFICATIONS_MENU_CLASS);
      publishFomioNotificationsMenuState(true, this.source);
    };

    this.#handleClose = () => this.close();

    if (typeof window !== "undefined") {
      window.addEventListener(
        FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
        this.#handleOpen
      );
      window.addEventListener(
        FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
        this.#handleClose
      );
    }

    this.#onRouteDidChange = () => this.close();
    this.router.on("routeDidChange", this.#onRouteDidChange);
  }

  willDestroy() {
    super.willDestroy(...arguments);

    if (typeof window !== "undefined") {
      window.removeEventListener(
        FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
        this.#handleOpen
      );
      window.removeEventListener(
        FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
        this.#handleClose
      );
    }

    this.router.off("routeDidChange", this.#onRouteDidChange);
    document.body?.classList.remove(FOMIO_NOTIFICATIONS_MENU_CLASS);
    publishFomioNotificationsMenuState(false, this.source);
  }

  #handleOpen;
  #handleClose;
  #onRouteDidChange;
  #panelResizeObserver;

  get panelClass() {
    return `fomio-notifications-menu fomio-notifications-menu--${this.source}`;
  }

  get ariaLabel() {
    return i18n(themePrefix("notifications_overlay.aria_label"));
  }

  get title() {
    return i18n(themePrefix("notifications_overlay.title"));
  }

  get shouldRender() {
    return Boolean(this.currentUser && this.isOpen);
  }

  get panelStyle() {
    if (this.source !== "desktop" || !this.anchorRect || typeof window === "undefined") {
      return null;
    }

    const sidebarRight =
      document.querySelector(".fomio-sidebar")?.getBoundingClientRect?.().right ??
      null;
    const preferredLeft =
      sidebarRight != null
        ? sidebarRight + this.DESKTOP_GAP
        : this.anchorRect.right - this.DESKTOP_WIDTH;
    const maxWidth = Math.min(
      this.DESKTOP_WIDTH,
      Math.max(
        280,
        window.innerWidth - preferredLeft - this.DESKTOP_MARGIN
      )
    );
    const left = Math.max(
      this.DESKTOP_MARGIN,
      Math.min(preferredLeft, window.innerWidth - maxWidth - this.DESKTOP_MARGIN)
    );
    const menuHeight =
      this.measuredHeight > 0
        ? this.measuredHeight
        : Math.min(
            this.DESKTOP_MAX_HEIGHT,
            Math.round(window.innerHeight * 0.78)
          );
    const belowTop = this.anchorRect.bottom + this.DESKTOP_GAP;
    const aboveTop = this.anchorRect.top - menuHeight - this.DESKTOP_GAP;
    const maxTop = window.innerHeight - menuHeight - this.DESKTOP_MARGIN;

    let top;
    if (sidebarRight != null && this.measuredFooterHeight > 0) {
      const triggerCenter = this.anchorRect.top + this.anchorRect.height / 2;
      const footerCenterOffset =
        menuHeight - this.measuredFooterHeight / 2;
      top = triggerCenter - footerCenterOffset;
    } else {
      top = belowTop;
      if (belowTop + menuHeight > window.innerHeight - this.DESKTOP_MARGIN) {
        top = aboveTop;
      }
    }
    top = Math.max(this.DESKTOP_MARGIN, Math.min(top, maxTop));

    return `top:${Math.round(top)}px;left:${Math.round(left)}px;width:${Math.round(
      maxWidth
    )}px;`;
  }

  @action
  close() {
    this.isOpen = false;
    this.anchorRect = null;
    this.measuredHeight = 0;
    this.measuredFooterHeight = 0;
    this.#panelResizeObserver?.disconnect();
    document.body?.classList.remove(FOMIO_NOTIFICATIONS_MENU_CLASS);
    publishFomioNotificationsMenuState(false, this.source);
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
      this.measuredFooterHeight = Math.round(
        element.querySelector(".panel-body-bottom")?.getBoundingClientRect()
          ?.height ?? 0
      );
    };

    measure();
    this.#panelResizeObserver?.disconnect();
    if (typeof ResizeObserver !== "undefined") {
      this.#panelResizeObserver = new ResizeObserver(() => measure());
      this.#panelResizeObserver.observe(element);
    }
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="fomio-notifications-menu-shell"
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
          {{#if this.source}}
            <header class="fomio-np-header">
              <span class="fomio-np-title">{{this.title}}</span>
            </header>
          {{/if}}
          <UserMenu @closeUserMenu={{this.close}} />
        </div>
      </div>
    {{/if}}
  </template>
}
