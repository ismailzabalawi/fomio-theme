export const FOMIO_USER_MENU_CLASS = "fomio-user-menu-open";
export const FOMIO_USER_MENU_OPEN_EVENT = "fomio:user-menu:open";
export const FOMIO_USER_MENU_CLOSE_EVENT = "fomio:user-menu:close";
export const FOMIO_USER_MENU_STATE_EVENT = "fomio:user-menu:state";

export function openFomioUserMenu(source = "desktop", anchorRect) {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(
    new CustomEvent(FOMIO_USER_MENU_OPEN_EVENT, {
      detail: { source, anchorRect },
    })
  );
}

export function closeFomioUserMenu() {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(new CustomEvent(FOMIO_USER_MENU_CLOSE_EVENT));
}

export function publishFomioUserMenuState(open, source = "desktop") {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(
    new CustomEvent(FOMIO_USER_MENU_STATE_EVENT, {
      detail: { open, source },
    })
  );
}
