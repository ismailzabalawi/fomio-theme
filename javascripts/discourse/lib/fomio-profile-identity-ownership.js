import {
  isAuthPath,
  isMeLandingSurfacePath,
  isOwnedProfileChildPath,
  isUserProfilePath,
} from "./fomio-mobile-nav-paths.js";

export function shouldRenderInlineProfileIdentity({
  currentPath,
  viewedUser,
}) {
  if (!viewedUser?.username || isAuthPath(currentPath)) {
    return false;
  }

  return false;
}

export function shouldHideSharedProfileHeader({
  currentPath,
  currentUser,
  isTouchShell,
}) {
  if (isAuthPath(currentPath)) {
    return false;
  }

  if (isTouchShell) {
    return (
      isMeLandingSurfacePath(currentPath, currentUser) ||
      isOwnedProfileChildPath(currentPath, currentUser)
    );
  }

  return isUserProfilePath(currentPath);
}
