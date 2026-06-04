const FILTER_HEADER_SELECTOR =
  ".user-notifications-filter summary.notifications-filter-header, .user-notifications-filter .notifications-filter-header";
const DISMISS_BUTTON_SELECTOR = ".navigation-controls .btn.dismiss-notifications";
const FILTER_ICON_CLASS = "fomio-notifications-filter-ph";
const DISMISS_ICON_CLASS = "fomio-notifications-dismiss-ph";
const FUNNEL_PATH =
  "M200 136a8 8 0 0 1-8 8H64a8 8 0 0 1 0-16h128a8 8 0 0 1 8 8m32-56H24a8 8 0 0 0 0 16h208a8 8 0 0 0 0-16m-80 96h-48a8 8 0 0 0 0 16h48a8 8 0 0 0 0-16";
const CHECK_PATH =
  "m229.66 77.66-128 128a8 8 0 0 1-11.32 0l-56-56a8 8 0 0 1 11.32-11.32L96 188.69 218.34 66.34a8 8 0 0 1 11.32 11.32";

let notificationsChromeObserver = null;

function createPhosphorIcon(pathD, className) {
  const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  icon.setAttribute("viewBox", "0 0 256 256");
  icon.setAttribute("class", className);
  icon.setAttribute("aria-hidden", "true");
  icon.setAttribute("focusable", "false");

  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path.setAttribute("d", pathD);
  icon.appendChild(path);

  return icon;
}

function isNotificationsInbox() {
  return (
    document.body.classList.contains("user-notifications-page") ||
    /\/notifications\/?$/.test(window.location?.pathname || "")
  );
}

export function decorateNotificationsFilterIcon() {
  if (typeof document === "undefined" || !document.body || !isNotificationsInbox()) {
    return false;
  }

  const header = document.querySelector(FILTER_HEADER_SELECTOR);
  if (!header) {
    return false;
  }

  const wrapper = header.querySelector(".select-kit-header-wrapper") ?? header;

  if (!wrapper.querySelector(`.${FILTER_ICON_CLASS}`)) {
    wrapper.prepend(createPhosphorIcon(FUNNEL_PATH, FILTER_ICON_CLASS));
  }

  header.classList.add("fomio-notifications-filter-header--icon");
  return true;
}

export function decorateNotificationsDismissIcon() {
  if (typeof document === "undefined" || !document.body || !isNotificationsInbox()) {
    return false;
  }

  const button = document.querySelector(DISMISS_BUTTON_SELECTOR);
  if (!button) {
    return false;
  }

  if (!button.querySelector(`.${DISMISS_ICON_CLASS}`)) {
    button.prepend(createPhosphorIcon(CHECK_PATH, DISMISS_ICON_CLASS));
  }

  button.classList.add("fomio-dismiss-notifications--icon");
  return true;
}

function isNotificationsChromeDecorated() {
  if (!isNotificationsInbox()) {
    return true;
  }

  const header = document.querySelector(FILTER_HEADER_SELECTOR);
  const filterReady =
    !header || Boolean(header.querySelector(`.${FILTER_ICON_CLASS}`));

  const button = document.querySelector(DISMISS_BUTTON_SELECTOR);
  const dismissReady =
    !button || Boolean(button.querySelector(`.${DISMISS_ICON_CLASS}`));

  return filterReady && dismissReady;
}

export function decorateNotificationsChromeIcons() {
  decorateNotificationsFilterIcon();
  decorateNotificationsDismissIcon();
  return isNotificationsChromeDecorated();
}

export function stopNotificationsFilterIconObserver() {
  notificationsChromeObserver?.disconnect();
  notificationsChromeObserver = null;
}

export function startNotificationsFilterIconObserver() {
  if (typeof document === "undefined" || typeof MutationObserver === "undefined") {
    decorateNotificationsChromeIcons();
    return;
  }

  stopNotificationsFilterIconObserver();

  decorateNotificationsChromeIcons();

  if (isNotificationsChromeDecorated()) {
    return;
  }

  const root =
    document.querySelector("#main-outlet .notification-history") ||
    document.querySelector("#main-outlet") ||
    document.body;

  notificationsChromeObserver = new MutationObserver(() => {
    decorateNotificationsChromeIcons();

    if (isNotificationsChromeDecorated()) {
      stopNotificationsFilterIconObserver();
    }
  });

  notificationsChromeObserver.observe(root, { childList: true, subtree: true });
}

export function scheduleNotificationsFilterIconDecoration() {
  if (typeof window === "undefined") {
    decorateNotificationsChromeIcons();
    return;
  }

  const run = () => {
    startNotificationsFilterIconObserver();
  };

  if (typeof window.requestAnimationFrame !== "function") {
    run();
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(run);
  });
}
