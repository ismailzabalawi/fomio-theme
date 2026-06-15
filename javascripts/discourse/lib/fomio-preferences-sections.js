export const FOMIO_PREFERENCES_SECTIONS = [
  {
    key: "account",
    icon: "circle-user",
    labelKey: "user.preferences_nav.account",
    subtitleKey: "preferences_overlay.account",
    href: "/my/preferences/account",
  },
  {
    key: "security",
    icon: "lock",
    labelKey: "user.preferences_nav.security",
    subtitleKey: "preferences_overlay.security",
    href: "/my/preferences/security",
  },
  {
    key: "profile",
    icon: "address-card",
    labelKey: "user.preferences_nav.profile",
    subtitleKey: "preferences_overlay.profile",
    href: "/my/preferences/profile",
  },
  {
    key: "emails",
    icon: "envelope",
    labelKey: "user.preferences_nav.emails",
    subtitleKey: "preferences_overlay.emails",
    href: "/my/preferences/emails",
  },
  {
    key: "notifications",
    icon: "bell",
    labelKey: "user.preferences_nav.notifications",
    subtitleKey: "preferences_overlay.notifications",
    href: "/my/preferences/notifications",
  },
  {
    key: "tracking",
    icon: "plus",
    labelKey: "user.preferences_nav.tracking",
    subtitleKey: "preferences_overlay.tracking",
    href: "/my/preferences/tracking",
  },
  {
    key: "users",
    icon: "users",
    labelKey: "user.preferences_nav.users",
    subtitleKey: "preferences_overlay.users",
    href: "/my/preferences/users",
  },
  {
    key: "interface",
    icon: "desktop",
    labelKey: "user.preferences_nav.interface",
    subtitleKey: "preferences_overlay.interface",
    href: "/my/preferences/interface",
  },
  {
    key: "navigation-menu",
    icon: "bars",
    labelKey: "user.preferences_nav.navigation_menu",
    subtitleKey: "preferences_overlay.navigation_menu",
    href: "/my/preferences/navigation-menu",
  },
];

export function isFomioPreferencesRootPath(path) {
  return /^\/(?:my\/preferences|u\/[^/]+\/preferences)\/?$/i.test(path || "");
}

export function isFomioPreferencesChildPath(path) {
  return /^\/(?:my\/preferences|u\/[^/]+\/preferences)\/.+/i.test(path || "");
}

export function hasFomioPreferencesMenuMarker(currentURL) {
  if (/\bfomio_menu=1\b/.test(currentURL || "")) {
    return true;
  }

  if (typeof window === "undefined") {
    return false;
  }

  return (
    /\bfomio_menu=1\b/.test(window.location?.search || "") ||
    window.sessionStorage?.getItem("fomio:preferences-menu") === "1"
  );
}

export function setFomioPreferencesMenuMarker() {
  if (typeof window === "undefined") {
    return;
  }

  window.sessionStorage?.setItem("fomio:preferences-menu", "1");
}

export function clearFomioPreferencesMenuMarker() {
  if (typeof window === "undefined") {
    return;
  }

  window.sessionStorage?.removeItem("fomio:preferences-menu");
}
