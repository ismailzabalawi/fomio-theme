/** Auth / Discourse-flow paths where the Fomio shell must not run. */
export const FOMIO_AUTH_PATH_PREFIXES = [
  "/login",
  "/signup",
  "/session/",
  "/user-api-key",
  "/password-reset",
  "/u/activate-account",
  "/u/account-created",
  "/invites",
  "/u/confirm",
  "/auth/",
];

export function isFomioAuthPath(pathname) {
  const path = pathname.split("?")[0];
  return FOMIO_AUTH_PATH_PREFIXES.some((prefix) => path.startsWith(prefix));
}
