// Discourse API utilities for preferences management.
// Handles theme updates, account operations, and user settings persistence.

import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

/**
 * Update user theme preference
 * @param {Object} user - Current user object
 * @param {string} mode - Theme mode: 'light', 'dark', 'system'
 * @param {Object} themeMap - Theme ID mapping { light, dark, system }
 * @returns {Promise<Object>} Updated user preferences
 */
export async function updateThemePreference(user, mode, themeMap = {}) {
  if (!user || !user.username) {
    throw new Error("User not authenticated");
  }

  try {
    // Resolve theme IDs from map, fallback to empty array for system mode
    const themeIds = themeMap[mode];
    const payload = Array.isArray(themeIds) ? themeIds : (themeIds ? [themeIds] : []);

    const response = await ajax(`/u/${user.username}/preferences.json`, {
      type: "PUT",
      data: {
        user_option: {
          theme_ids: payload,
        },
      },
    });

    return response;
  } catch (error) {
    popupAjaxError(error);
    throw error;
  }
}

/**
 * Sign out the current user
 * @param {Object} user - Current user object
 * @returns {Promise<void>}
 */
export async function signOutUser(user) {
  try {
    await ajax("/session.json", {
      type: "DELETE",
    });

    // Clear user session
    if (user) {
      user.clearNotifications?.();
    }

    // Redirect to home
    window.location.href = "/";
  } catch (error) {
    popupAjaxError(error);
    throw error;
  }
}

/**
 * Request account deletion (initiates multi-step confirmation flow)
 * @param {Object} user - Current user object
 * @returns {Promise<void>}
 */
export async function requestAccountDeletion(user) {
  if (!user || !user.username) {
    throw new Error("User not authenticated");
  }

  try {
    // Step 1: Request deletion (triggers confirmation email)
    const response = await ajax(`/u/${user.username}/delete-account.json`, {
      type: "POST",
      data: {
        confirm: false, // First step: request only
      },
    });

    // Would then navigate to confirmation page
    window.location.href = `/u/${user.username}/delete-account-confirm`;

    return response;
  } catch (error) {
    popupAjaxError(error);
    throw error;
  }
}

/**
 * Update notification preferences
 * @param {Object} user - Current user object
 * @param {string} setting - Setting key
 * @param {*} value - New value
 * @returns {Promise<Object>} Updated preferences
 */
export async function updateNotificationPreference(user, setting, value) {
  if (!user || !user.username) {
    throw new Error("User not authenticated");
  }

  try {
    const data = {
      user_option: {
        [setting]: value,
      },
    };

    const response = await ajax(`/u/${user.username}/preferences.json`, {
      type: "PUT",
      data,
    });

    return response;
  } catch (error) {
    popupAjaxError(error);
    throw error;
  }
}

/**
 * Get user's current preferences
 * @param {Object} user - Current user object
 * @returns {Promise<Object>} User preferences
 */
export async function getUserPreferences(user) {
  if (!user || !user.username) {
    throw new Error("User not authenticated");
  }

  try {
    const response = await ajax(`/u/${user.username}/preferences.json`, {
      type: "GET",
    });

    return response.user;
  } catch (error) {
    popupAjaxError(error);
    throw error;
  }
}

/**
 * Get current user's theme mode based on theme IDs
 * @param {Object} user - Current user object
 * @param {Object} site - Site object with available themes
 * @returns {string} Theme mode: 'light', 'dark', or 'system'
 */
export function getCurrentThemeMode(user, site) {
  if (!user) {
    return "system";
  }

  const themeIds = user.theme_ids || [];

  // If no theme is set, return system (Discourse default behavior)
  if (!themeIds.length) {
    return "system";
  }

  // If site themes are available, try to match against known theme names
  if (site && site.themes) {
    const themes = site.themes || [];
    for (const themeId of themeIds) {
      const theme = themes.find((t) => t.id === themeId);
      if (theme) {
        const name = theme.name?.toLowerCase() || "";
        if (name.includes("dark")) {
          return "dark";
        }
        if (name.includes("fomio") && !name.includes("dark")) {
          return "light";
        }
      }
    }
  }

  // Fallback to system if we can't determine the theme
  return "system";
}

/**
 * Track user activity for privacy settings
 * @param {Object} user - Current user object
 * @param {string} setting - Privacy setting key
 * @returns {Promise<Object>} Updated user
 */
export async function updatePrivacySetting(user, setting, value) {
  if (!user || !user.username) {
    throw new Error("User not authenticated");
  }

  try {
    const response = await ajax(`/u/${user.username}.json`, {
      type: "PUT",
      data: {
        [setting]: value,
      },
    });

    return response.user;
  } catch (error) {
    popupAjaxError(error);
    throw error;
  }
}
