export const FOMIO_NOTIFICATIONS_MENU_CLASS = "fomio-notifications-menu-open";
export const FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT =
  "fomio:notifications-menu:open";
export const FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT =
  "fomio:notifications-menu:close";

export function openFomioNotificationsMenu(source = "desktop") {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(
    new CustomEvent(FOMIO_NOTIFICATIONS_MENU_OPEN_EVENT, {
      detail: { source },
    })
  );
}

export function closeFomioNotificationsMenu() {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(new CustomEvent(FOMIO_NOTIFICATIONS_MENU_CLOSE_EVENT));
}

export function isFomioNotificationsMenuOpen() {
  if (typeof document === "undefined") {
    return false;
  }

  return document.body?.classList.contains(FOMIO_NOTIFICATIONS_MENU_CLASS);
}
