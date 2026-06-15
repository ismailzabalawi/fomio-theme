export const FOMIO_PREFERENCES_MENU_CLASS = "fomio-preferences-menu-open";
export const FOMIO_PREFERENCES_MENU_OPEN_EVENT =
  "fomio:preferences-menu:open";
export const FOMIO_PREFERENCES_MENU_CLOSE_EVENT =
  "fomio:preferences-menu:close";
export const FOMIO_PREFERENCES_MENU_STATE_EVENT =
  "fomio:preferences-menu:state";

export function openFomioPreferencesMenu(source = "desktop", anchorRect) {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(
    new CustomEvent(FOMIO_PREFERENCES_MENU_OPEN_EVENT, {
      detail: { source, anchorRect },
    })
  );
}

export function closeFomioPreferencesMenu() {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(new CustomEvent(FOMIO_PREFERENCES_MENU_CLOSE_EVENT));
}

export function publishFomioPreferencesMenuState(open, source = "desktop") {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(
    new CustomEvent(FOMIO_PREFERENCES_MENU_STATE_EVENT, {
      detail: { open, source },
    })
  );
}
