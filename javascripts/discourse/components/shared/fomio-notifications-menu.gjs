import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import UserMenu from "discourse/components/user-menu/menu";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import {
  closeFomioNotificationsMenu,
  FOMIO_NOTIFICATIONS_MENU_CLASS,
  FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT,
  FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT,
} from "../../lib/fomio-notifications-menu";

export default class FomioNotificationsMenu extends Component {
  @service currentUser;
  @service router;

  @tracked isOpen = false;
  @tracked source = "desktop";

  constructor(owner, args) {
    super(owner, args);

    this.#handleOpen = (event) => {
      if (!this.currentUser) {
        return;
      }

      this.source = event?.detail?.source === "mobile" ? "mobile" : "desktop";
      this.isOpen = true;
      document.body?.classList.add(FOMIO_NOTIFICATIONS_MENU_CLASS);
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
  }

  #handleOpen;
  #handleClose;
  #onRouteDidChange;

  get panelClass() {
    return `fomio-notifications-menu fomio-notifications-menu--${this.source}`;
  }

  get ariaLabel() {
    return i18n(themePrefix("notifications_overlay.aria_label"));
  }

  @action
  close() {
    this.isOpen = false;
    document.body?.classList.remove(FOMIO_NOTIFICATIONS_MENU_CLASS);
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
  focusPanel(element) {
    element.focus();
  }

  <template>
    {{#if (and this.currentUser this.isOpen)}}
      <div
        class="fomio-notifications-menu-shell"
        role="presentation"
        {{on "click" this.closeFromBackdrop}}
      >
        <div
          class={{this.panelClass}}
          role="dialog"
          aria-modal="true"
          aria-label={{this.ariaLabel}}
          tabindex="-1"
          {{didInsert this.focusPanel}}
          {{on "keydown" this.handleKeydown}}
        >
          <UserMenu @closeUserMenu={{this.close}} />
        </div>
      </div>
    {{/if}}
  </template>
}
