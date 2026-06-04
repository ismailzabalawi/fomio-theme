const FILTER_HEADER_SELECTOR =
  ".user-notifications-filter .select-kit.notifications-filter .notifications-filter-header";
const ICON_CLASS = "fomio-notifications-filter-ph";
const ICON_SYMBOL_ID = "fomio-ph-funnel-simple";

function createFilterIcon() {
  const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  icon.setAttribute("viewBox", "0 0 256 256");
  icon.setAttribute("class", ICON_CLASS);
  icon.setAttribute("aria-hidden", "true");
  icon.setAttribute("focusable", "false");

  const use = document.createElementNS("http://www.w3.org/2000/svg", "use");
  use.setAttribute("href", `#${ICON_SYMBOL_ID}`);
  icon.appendChild(use);

  return icon;
}

export function decorateNotificationsFilterIcon() {
  if (typeof document === "undefined" || !document.body) {
    return;
  }

  if (!document.body.classList.contains("user-notifications-page")) {
    return;
  }

  const header = document.querySelector(FILTER_HEADER_SELECTOR);
  if (!header) {
    return;
  }

  const wrapper = header.querySelector(".select-kit-header-wrapper") ?? header;
  if (wrapper.querySelector(`.${ICON_CLASS}`)) {
    return;
  }

  wrapper.prepend(createFilterIcon());
  header.classList.add("fomio-notifications-filter-header--icon");
}

export function scheduleNotificationsFilterIconDecoration() {
  if (typeof window === "undefined") {
    decorateNotificationsFilterIcon();
    return;
  }

  if (typeof window.requestAnimationFrame !== "function") {
    decorateNotificationsFilterIcon();
    return;
  }

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      decorateNotificationsFilterIcon();
    });
  });
}
