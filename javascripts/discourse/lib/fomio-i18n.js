import { i18n } from "discourse-i18n";

/** Client strings under `en.js.fomio.*` in locales/en.yml (editable in the theme editor). */
export function fomioT(key, options) {
  return i18n(`fomio.${key}`, options);
}

/** For templates that need the raw key passed to {{i18n}}. */
export function fomioI18nKey(key) {
  return `fomio.${key}`;
}
