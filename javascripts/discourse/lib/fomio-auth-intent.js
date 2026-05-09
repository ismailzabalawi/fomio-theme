const RETURN_CONTEXT_KEY = "fomio_auth_return_context";
const INTENT_KEY = "fomio_auth_intent";
const INTENT_TS_KEY = "fomio_auth_intent_ts";
const MAX_AGE_MS = 15 * 60 * 1000;

/** Set when full-page navigation is needed before opening the native composer post-login. */
export const POST_LOGIN_OPEN_COMPOSER_KEY = "fomio_post_login_open_composer";

const BLOCKED_PREFIXES = ["/auth/", "/login", "/session/"];

function now() {
  return Date.now();
}

function isBlockedPath(pathname) {
  return BLOCKED_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

export function normalizeSafeInternalPath(candidate) {
  if (!candidate || typeof window === "undefined") {
    return null;
  }

  try {
    const url = new URL(candidate, window.location.origin);
    if (url.origin !== window.location.origin) {
      return null;
    }

    const path = `${url.pathname}${url.search}${url.hash}`;
    if (!path.startsWith("/") || isBlockedPath(url.pathname)) {
      return null;
    }

    return path;
  } catch {
    return null;
  }
}

export function storeAuthReturnContext(candidate) {
  if (typeof window === "undefined") {
    return;
  }

  const safePath = normalizeSafeInternalPath(candidate);
  if (!safePath) {
    return;
  }

  try {
    window.sessionStorage.setItem(RETURN_CONTEXT_KEY, safePath);
  } catch {
    // Ignore storage failures; auth fallback remains Discourse-native.
  }
}

export function storeAuthIntent(intent) {
  if (typeof window === "undefined" || !intent) {
    return;
  }

  try {
    window.sessionStorage.setItem(INTENT_KEY, intent);
    window.sessionStorage.setItem(INTENT_TS_KEY, String(now()));
  } catch {
    // Ignore storage failures.
  }
}

function readIntentFromStorage(consume) {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const tsRaw = window.sessionStorage.getItem(INTENT_TS_KEY);
    const ts = tsRaw ? parseInt(tsRaw, 10) : NaN;
    if (Number.isNaN(ts) || now() - ts > MAX_AGE_MS) {
      window.sessionStorage.removeItem(INTENT_KEY);
      window.sessionStorage.removeItem(INTENT_TS_KEY);
      return null;
    }

    const intent = window.sessionStorage.getItem(INTENT_KEY);
    if (consume && intent) {
      window.sessionStorage.removeItem(INTENT_KEY);
      window.sessionStorage.removeItem(INTENT_TS_KEY);
    }
    return intent;
  } catch {
    return null;
  }
}

/**
 * Read auth intent for display on login/signup without consuming it.
 * Consumption happens after successful auth (theme-initializer resume).
 */
export function peekAuthIntent() {
  return readIntentFromStorage(false);
}

export function consumeAuthIntent() {
  return readIntentFromStorage(true);
}

export function consumeAuthReturnContext() {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const value = window.sessionStorage.getItem(RETURN_CONTEXT_KEY);
    window.sessionStorage.removeItem(RETURN_CONTEXT_KEY);
    return normalizeSafeInternalPath(value);
  } catch {
    return null;
  }
}

export function redirectToLoginWithIntent(intent, candidatePath) {
  if (typeof window === "undefined") {
    return;
  }

  storeAuthReturnContext(candidatePath ?? window.location.pathname);
  storeAuthIntent(intent);

  // Keep explicit web-auth marker to avoid app-handoff collisions.
  window.location.href = "/login?fomio_web=1";
}
