const fs = require('fs');
const file = '/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/fomio-owned-notifications.gjs';
let content = fs.readFileSync(file, 'utf8');

// Imports
const importsToAdd = `
import { fomioPathnameNoQuery, fomioPathsEqual } from "../lib/fomio-router-pathname";
import icon from "discourse/helpers/d-icon";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { fn } from "@ember/helper";
`;
content = content.replace('import { service } from "@ember/service";', 'import { service } from "@ember/service";\n' + importsToAdd);
content = content.replace('import { and, not } from "discourse/truth-helpers";', 'import { and, not, eq } from "discourse/truth-helpers";');

// In class FomioOwnedNotifications:
const classAdditions = `
  @service siteSettings;

  @tracked pluginRows = [];
  /** When false, accordion follows active route group. */
  @tracked disclosureUserOverride = false;
  /** Expanded panel when overriden; 'none' = all collapsed. */
  @tracked disclosureExpandedId = null;

  get pathNoQuery() {
    return fomioPathnameNoQuery(this.router.currentURL);
  }

  get username() {
    const m = /^\\/u\\/([^/]+)\\/notifications/.exec(this.pathNoQuery);
    if (m) {
      return decodeURIComponent(m[1]);
    }
    if (
      this.pathNoQuery === "/notifications" ||
      this.pathNoQuery.startsWith("/notifications/")
    ) {
      return this.currentUser?.username ?? null;
    }
    return null;
  }

  get basePath() {
    const u = this.username;
    return u ? \`/u/\${u}/notifications\` : null;
  }

  isActiveForPath(suffix) {
    const base = this.basePath;
    if (!base) return false;
    if (suffix === "") return fomioPathsEqual(this.pathNoQuery, base);
    return fomioPathsEqual(this.pathNoQuery, \`\${base}/\${suffix}\`);
  }

  normalizePathForCompare(href) {
    try {
      const u = new URL(href, window.location.origin);
      return u.pathname;
    } catch {
      return href.split("?")[0];
    }
  }

  isActivePath(fullPath) {
    return fomioPathsEqual(this.pathNoQuery, fullPath);
  }

  get coreRows() {
    const base = this.basePath;
    if (!base) return [];

    const out = [
      {
        id: "all",
        href: getURL(base),
        label: i18n("user.filters.all"),
        isActive: this.isActiveForPath(""),
      },
      {
        id: "responses",
        href: getURL(\`\${base}/responses\`),
        label: i18n("user_action_groups.5"),
        isActive: this.isActiveForPath("responses"),
      },
    ];

    if (this.siteSettings.enable_mentions) {
      out.push({
        id: "mentions",
        href: getURL(\`\${base}/mentions\`),
        label: i18n("user_action_groups.7"),
        isActive: this.isActiveForPath("mentions"),
      });
    }

    out.push(
      {
        id: "likes-received",
        href: getURL(\`\${base}/likes-received\`),
        label: i18n("user_action_groups.2"),
        isActive: this.isActiveForPath("likes-received"),
      },
      {
        id: "links",
        href: getURL(\`\${base}/links\`),
        label: i18n("user_action_groups.17"),
        isActive: this.isActiveForPath("links"),
      },
      {
        id: "edits",
        href: getURL(\`\${base}/edits\`),
        label: i18n("user_action_groups.11"),
        isActive: this.isActiveForPath("edits"),
      }
    );

    return out;
  }

  get allNavRows() {
    const plugins = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));
    return [...this.coreRows, ...plugins];
  }

  rowGroupId(rowId) {
    if (String(rowId).startsWith("plugin-")) {
      return "more";
    }
    switch (rowId) {
      case "all":
        return "all";
      case "responses":
      case "mentions":
        return "conversations";
      case "likes-received":
      case "links":
        return "engagement";
      case "edits":
        return "changes";
      default:
        return "more";
    }
  }

  get activeGroupId() {
    const row = this.allNavRows.find((r) => r.isActive);
    if (!row) {
      return "all";
    }
    return this.rowGroupId(row.id);
  }

  get openDisclosureGroupId() {
    if (!this.disclosureUserOverride) {
      return this.activeGroupId;
    }
    return this.disclosureExpandedId;
  }

  get disclosureGroups() {
    const base = this.basePath;
    if (!base) {
      return [];
    }

    const rowById = new Map(this.coreRows.map((r) => [r.id, r]));

    const mk = (id, labelKey, rowIds) => {
      const rows = rowIds
        .map((rid) => rowById.get(rid))
        .filter(Boolean);
      return {
        id,
        label: i18n(themePrefix(labelKey)),
        panelId: \`fomio-owned-notifications-panel-\${id}\`,
        triggerId: \`fomio-owned-notifications-trigger-\${id}\`,
        rows,
      };
    };

    const groups = [
      mk("all", "notifications_submenu.group_all", ["all"]),
      mk("conversations", "notifications_submenu.group_conversations", [
        "responses",
        ...(this.siteSettings.enable_mentions ? ["mentions"] : []),
      ]),
      mk("engagement", "notifications_submenu.group_engagement", [
        "likes-received",
        "links",
      ]),
      mk("changes", "notifications_submenu.group_changes", ["edits"]),
    ];

    const moreRows = this.pluginRows.map((p) => ({
      ...p,
      isActive: this.isActivePath(this.normalizePathForCompare(p.href)),
    }));

    if (moreRows.length > 0) {
      groups.push({
        id: "more",
        label: i18n(themePrefix("notifications_submenu.group_more")),
        panelId: "fomio-owned-notifications-panel-more",
        triggerId: "fomio-owned-notifications-trigger-more",
        rows: moreRows,
      });
    }

    return groups;
  }

  @action
  toggleDisclosureGroup(groupId) {
    const cur = this.openDisclosureGroupId;
    this.disclosureUserOverride = true;
    if (cur === groupId) {
      this.disclosureExpandedId = "none";
    } else {
      this.disclosureExpandedId = groupId;
    }
  }

  @action
  extractPluginRows() {
    const nav = document.querySelector("#main-outlet .user-main .user-navigation.user-navigation-secondary");
    const horiz = nav?.querySelector(":scope > nav.horizontal-overflow-nav");
    if (!horiz) return;
    const CORE_NOTIFICATIONS_NAV_SUBSTR = "user-nav__notifications-";
    const pills = horiz.querySelectorAll("ul.nav-pills > li");
    const out = [];
    pills.forEach((li, index) => {
      const cls = li.className?.toString() ?? "";
      if (cls.includes(CORE_NOTIFICATIONS_NAV_SUBSTR)) {
        return;
      }
      const a = li.querySelector("a[href]");
      if (!a) return;
      const rawHref = a.getAttribute("href");
      const label = (a.textContent || "").trim().replace(/\\s+/g, " ");
      if (!rawHref || !label) return;
      out.push({
        id: \`plugin-\${index}-\${getURL(rawHref)}\`,
        href: getURL(rawHref),
        label,
      });
    });
    this.pluginRows = out;
  }
`;

content = content.replace('  didSuppressNative = false;', '  didSuppressNative = false;\n' + classAdditions);

// Add extractPluginRows to syncFromRoute
content = content.replace('this.loadInitial(ctx.requestPath);', 'this.loadInitial(ctx.requestPath);\n    setTimeout(() => this.extractPluginRows(), 100);');

const accordionTemplate = `
          <div class="fomio-owned-notifications__accordion" {{didInsert this.extractPluginRows}}>
            {{#each this.disclosureGroups as |g|}}
              <div class="fomio-owned-notifications-group {{if (eq this.openDisclosureGroupId g.id) 'is-expanded'}}">
                <button
                  id={{g.triggerId}}
                  type="button"
                  class="fomio-owned-notifications-group__header"
                  aria-expanded={{if (eq this.openDisclosureGroupId g.id) "true" "false"}}
                  aria-controls={{g.panelId}}
                  {{on "click" (fn this.toggleDisclosureGroup g.id)}}
                >
                  {{g.label}}
                  {{icon "chevron-down"}}
                </button>
                <div
                  id={{g.panelId}}
                  class="fomio-owned-notifications-group__panel"
                  role="region"
                  aria-labelledby={{g.triggerId}}
                  hidden={{if (eq this.openDisclosureGroupId g.id) false true}}
                >
                  {{#each g.rows as |row|}}
                    <a
                      href={{row.href}}
                      class="fomio-owned-notifications-group__link {{if row.isActive 'is-active'}}"
                      aria-current={{if row.isActive "page"}}
                    >
                      {{row.label}}
                    </a>
                  {{/each}}
                </div>
              </div>
            {{/each}}
          </div>
`;

content = content.replace('</header>', '</header>\n' + accordionTemplate);

fs.writeFileSync(file, content, 'utf8');
console.log('Update script completed successfully.');
