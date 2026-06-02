export const AUTH_PATH_PREFIXES = [
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

export const DISCOURSE_NATIVE_PATH_PREFIXES = ["/admin"];

export function normalizePath(path) {
  return path?.split("?")[0]?.replace(/\/+$/, "") || "/";
}

export function isAuthPath(path) {
  const normalizedPath = normalizePath(path);
  return AUTH_PATH_PREFIXES.some((prefix) => normalizedPath.startsWith(prefix));
}

export function isDiscourseNativePath(path) {
  const normalizedPath = normalizePath(path);
  return DISCOURSE_NATIVE_PATH_PREFIXES.some((prefix) =>
    normalizedPath.startsWith(prefix)
  );
}

export function isFomioShellPath(path) {
  const normalizedPath = normalizePath(path);
  return (
    !isAuthPath(normalizedPath) && !isDiscourseNativePath(normalizedPath)
  );
}
