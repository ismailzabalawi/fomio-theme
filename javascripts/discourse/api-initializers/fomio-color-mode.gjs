import { apiInitializer } from "discourse/lib/api";
import Session from "discourse/models/session";

/**
 * Keeps `html.fomio-color-dark` in sync with Discourse’s active color-scheme
 * stylesheet (link.dark-scheme `media`) so `--fomio-*` tokens in common.scss
 * match light vs dark palettes from about.json.
 *
 * Verified: discourse/app/helpers/application_helper.rb — dual link tags with
 * classes `light-scheme` / `dark-scheme`; interface-color.js toggles `media`.
 */

function fomioDarkSchemeIsActive() {
  const session = Session.current();
  const darkLink = document.querySelector("link.dark-scheme");

  if (!darkLink) {
    return Boolean(session?.defaultColorSchemeIsDark);
  }

  const { media } = darkLink;
  if (media === "none") {
    return false;
  }
  if (media === "all") {
    return true;
  }
  try {
    return window.matchMedia(media).matches;
  } catch {
    return false;
  }
}

function applyFomioColorDarkClass() {
  document.documentElement.classList.toggle(
    "fomio-color-dark",
    fomioDarkSchemeIsActive()
  );
}

function observeColorSchemeLink(className) {
  const link = document.querySelector(`link.${className}`);
  if (!link || link.dataset.fomioColorObserved) {
    return;
  }
  link.dataset.fomioColorObserved = "1";
  new MutationObserver(applyFomioColorDarkClass).observe(link, {
    attributes: true,
    attributeFilter: ["media"],
  });
}

export default apiInitializer("1.8.0", (api) => {
  observeColorSchemeLink("dark-scheme");
  observeColorSchemeLink("light-scheme");
  applyFomioColorDarkClass();

  const prefersDark = window.matchMedia("(prefers-color-scheme: dark)");
  prefersDark.addEventListener("change", applyFomioColorDarkClass);

  api.onAppEvent("interface-color:changed", applyFomioColorDarkClass);
});
