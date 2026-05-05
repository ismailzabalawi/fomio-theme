import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// ── Icons ─────────────────────────────────────────────────────

const IcoPlus = <template>
  <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M12 5v14M5 12h14" />
  </svg>
</template>;

const IcoH2 = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M4 6v12M14 6v12M4 12h10M18 8a3 3 0 0 1 6 0c0 4-6 5-6 10h6" />
  </svg>
</template>;

const IcoQuote = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M7 7h4v6H7V7zM13 7h4v6h-4V7zM7 13c0 4 2 5 4 5M13 13c0 4 2 5 4 5" />
  </svg>
</template>;

const IcoDivider = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M5 12h14" />
  </svg>
</template>;

const IcoImage = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M3 5h18v14H3zM3 16l5-5 4 4 3-3 6 6" />
  </svg>
</template>;

const IcoBold = <template>
  <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M7 4h6a4 4 0 0 1 0 8H7zM7 12h7a4 4 0 0 1 0 8H7z" />
  </svg>
</template>;

const IcoItalic = <template>
  <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M11 4h8M5 20h8M14 4l-4 16" />
  </svg>
</template>;

const IcoLink = <template>
  <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 0 0-5.66-5.66l-1.5 1.5M14 10a4 4 0 0 1-5.66 0l-3 3a4 4 0 0 0 5.66 5.66l1.5-1.5" />
  </svg>
</template>;

// ── Block model ───────────────────────────────────────────────

let _blockIdCounter = 0;

function createBlock(type = "paragraph", content = "") {
  return { id: `fomio-b-${++_blockIdCounter}`, type, content, url: "", alt: "", caption: "" };
}

// ── Markdown serializer (module-level pure function) ──────────

function serializeBlocks(blocks) {
  return blocks
    .map((block) => {
      switch (block.type) {
        case "h2":      return `## ${block.content}`;
        case "h3":      return `### ${block.content}`;
        case "quote":   return block.content.split("\n").map((l) => `> ${l}`).join("\n");
        case "divider": return "---";
        case "image":
          if (!block.url) return "";
          return `![${block.alt || ""}](${block.url})${block.caption ? `\n*${block.caption}*` : ""}`;
        case "onebox":  return block.url || block.content || "";
        default:        return block.content || "";
      }
    })
    .join("\n\n");
}

// ── Markdown parser (for loading existing drafts) ─────────────

function parseMarkdownToBlocks(markdown) {
  if (!markdown?.trim()) return [createBlock("paragraph", "")];
  const lines = markdown.split("\n");
  const blocks = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.startsWith("## "))        { blocks.push(createBlock("h2", line.slice(3))); i++; }
    else if (line.startsWith("### "))  { blocks.push(createBlock("h3", line.slice(4))); i++; }
    else if (line === "---")           { blocks.push(createBlock("divider", "")); i++; }
    else if (line.startsWith("> ")) {
      const qs = [];
      while (i < lines.length && lines[i].startsWith("> ")) { qs.push(lines[i].slice(2)); i++; }
      blocks.push(createBlock("quote", qs.join("\n")));
    } else if (line.startsWith("![")) {
      const m = line.match(/!\[([^\]]*)\]\(([^)]+)\)/);
      if (m) blocks.push({ ...createBlock("image"), alt: m[1], url: m[2] });
      i++;
    } else if (/^https?:\/\//.test(line.trim())) {
      blocks.push(createBlock("onebox", line.trim()));
      i++;
    } else if (line.trim()) {
      const ps = [];
      while (i < lines.length && lines[i].trim() && !lines[i].startsWith("#") && !lines[i].startsWith(">") && lines[i] !== "---") {
        ps.push(lines[i]); i++;
      }
      blocks.push(createBlock("paragraph", ps.join("\n")));
    } else { i++; }
  }
  return blocks.length > 0 ? blocks : [createBlock("paragraph", "")];
}

// ── Source text per block (module-level helper) ───────────────

function blockSourceText(block) {
  switch (block.type) {
    case "h2":      return `## ${block.content}`;
    case "h3":      return `### ${block.content}`;
    case "quote":   return block.content.split("\n").map((l) => `> ${l}`).join("\n");
    case "divider": return "---";
    case "image":   return `![${block.alt || ""}](${block.url})`;
    case "onebox":  return block.url || block.content || "";
    default:        return block.content;
  }
}

// ── Word / char helpers (module-level) ────────────────────────

function countWords(blocks) {
  const text = blocks.filter((b) => b.type !== "divider" && b.type !== "image").map((b) => b.content || b.url || "").join(" ");
  return text.trim() ? text.trim().split(/\s+/).length : 0;
}

function countChars(blocks) {
  return blocks.map((b) => (b.content || b.url || "").length).reduce((a, v) => a + v, 0);
}

// ── Slash menu items ──────────────────────────────────────────

const SLASH_ITEMS = [
  { type: "h2",      label: "Heading",  desc: "Section title",     hint: "##",  enabled: true  },
  { type: "quote",   label: "Quote",    desc: "Set off a passage",  hint: ">",   enabled: true  },
  { type: "divider", label: "Divider",  desc: "Horizontal rule",    hint: "---", enabled: true  },
  { type: "image",   label: "Image",    desc: "Coming soon",        hint: "",    enabled: false },
];

// ── Slash menu icon (module-level component) ──────────────────

const SlashIcon = <template>
  {{#if (eq @type "h2")}}     <IcoH2 />     {{/if}}
  {{#if (eq @type "quote")}}  <IcoQuote />  {{/if}}
  {{#if (eq @type "divider")}}<IcoDivider />{{/if}}
  {{#if (eq @type "image")}}  <IcoImage />  {{/if}}
</template>;

// ── Floating selection toolbar (module-level component) ───────

class FomioFloatingToolbar extends Component {
  @action applyBold(e)   { e.preventDefault(); this.args.onWrap("**", "**"); }
  @action applyItalic(e) { e.preventDefault(); this.args.onWrap("*", "*"); }
  @action applyLink(e) {
    e.preventDefault();
    const url = prompt(i18n(themePrefix("composer.link_prompt")));
    if (url) this.args.onWrap("[", `](${url})`);
  }

  <template>
    <div class="fomio-cm-pop" role="toolbar" aria-label={{i18n (themePrefix "composer.toolbar_label")}}>
      <button type="button" class="fomio-cm-pop-tool" title="Bold ⌘B" aria-label={{i18n (themePrefix "composer.format_bold")}} {{on "mousedown" this.applyBold}}>
        <IcoBold />
      </button>
      <button type="button" class="fomio-cm-pop-tool" title="Italic ⌘I" aria-label={{i18n (themePrefix "composer.format_italic")}} {{on "mousedown" this.applyItalic}}>
        <IcoItalic />
      </button>
      <span class="fomio-cm-pop-divider" aria-hidden="true"></span>
      <button type="button" class="fomio-cm-pop-tool" title="Link ⌘K" aria-label={{i18n (themePrefix "composer.format_link")}} {{on "mousedown" this.applyLink}}>
        <IcoLink />
      </button>
    </div>
  </template>
}

// ── Individual block ──────────────────────────────────────────

class FomioBlock extends Component {
  get isDivider() { return this.args.blockData.type === "divider"; }
  get isImage()   { return this.args.blockData.type === "image"; }

  get blockClass() {
    const base = `fomio-cm-block fomio-cm-block--${this.args.blockData.type}`;
    return this.args.isCurrent ? `${base} is-current` : base;
  }

  get placeholder() {
    switch (this.args.blockData.type) {
      case "h2":    return i18n(themePrefix("composer.block_ph_heading"));
      case "h3":    return i18n(themePrefix("composer.block_ph_heading"));
      case "quote": return i18n(themePrefix("composer.block_ph_quote"));
      default:      return this.args.isFirst
        ? i18n(themePrefix("composer.block_ph_first"))
        : i18n(themePrefix("composer.block_ph"));
    }
  }

  @action onInput(e)   { this.args.onEdit(this.args.blockData.id, e.target.value); }
  @action onKeydown(e) { this.args.onKeydown(this.args.blockData.id, e); }
  @action onFocus()    { this.args.onFocus(this.args.blockData.id); }
  @action onSelect()   { this.args.onSelect(this.args.blockData.id); }

  <template>
    <div class={{this.blockClass}} data-block-id={{@blockData.id}}>
      <div class="fomio-cm-block-gutter">
        <button
          type="button"
          class="fomio-cm-handle"
          title={{i18n (themePrefix "composer.add_block")}}
          aria-label={{i18n (themePrefix "composer.add_block")}}
          {{on "click" (fn @onAddAfter @blockData.id)}}
        >
          <IcoPlus />
        </button>
      </div>

      <div class="fomio-cm-block-content">
        {{#if this.isDivider}}
          <div class="fomio-cm-divider-line" role="separator"></div>
        {{else if this.isImage}}
          <div class="fomio-cm-image-placeholder">
            <IcoImage />
            <span>{{i18n (themePrefix "composer.image_coming_soon")}}</span>
          </div>
        {{else}}
          <textarea
            class="fomio-cm-block-input"
            rows="1"
            placeholder={{this.placeholder}}
            data-block-type={{@blockData.type}}
            {{on "input" this.onInput}}
            {{on "keydown" this.onKeydown}}
            {{on "focus" this.onFocus}}
            {{on "select" this.onSelect}}
          >{{@blockData.content}}</textarea>
          {{#if @showSource}}
            <div class="fomio-cm-source-line">{{blockSourceText @blockData}}</div>
          {{/if}}
        {{/if}}
      </div>
    </div>
  </template>
}

// ── Main block editor component ───────────────────────────────

export default class FomioBlockEditor extends Component {
  @service composer;

  @tracked blocks = [];
  @tracked activeBlockId = null;
  @tracked slashMenuBlockId = null;
  @tracked toolbarBlockId = null;
  @tracked sourceMode = false;

  constructor(owner, args) {
    super(owner, args);
    this._initFromDraft();
  }

  _initFromDraft() {
    const existing = this.composer.model?.reply;
    this.blocks = existing?.trim()
      ? parseMarkdownToBlocks(existing)
      : [createBlock("paragraph", "")];
    if (this.blocks.length > 0) this.activeBlockId = this.blocks[0].id;
    this._emitStatus();
    // Auto-resize all textareas after DOM renders so loaded drafts don't clip
    Promise.resolve().then(() => this._resizeAllTextareas());
  }

  _resizeAllTextareas() {
    document.querySelectorAll(".fomio-cm-block-input").forEach((el) => this._autoResize(el));
  }

  // ── Computed ──────────────────────────────────────────────────

  get words()          { return countWords(this.blocks); }
  get chars()          { return countChars(this.blocks); }
  get readingMinutes() { return Math.max(1, Math.ceil(this.words / 200)); }

  get outlineItems() {
    return this.blocks
      .filter((b) => b.type === "h2" || b.type === "h3")
      .map((b) => ({ id: b.id, level: b.type, text: b.content }));
  }

  get activeBlockIndex() {
    const idx = this.blocks.findIndex((b) => b.id === this.activeBlockId);
    return idx + 1;
  }

  get serialized() {
    return serializeBlocks(this.blocks);
  }

  // ── Block mutations ───────────────────────────────────────────

  @action
  editBlock(id, content) {
    this.blocks = this.blocks.map((b) => b.id === id ? { ...b, content } : b);
    this._sync();
  }

  @action
  addBlockAfter(id) {
    const idx = this.blocks.findIndex((b) => b.id === id);
    const next = createBlock("paragraph", "");
    this.blocks = [...this.blocks.slice(0, idx + 1), next, ...this.blocks.slice(idx + 1)];
    this.activeBlockId = next.id;
    this._focusBlock(next.id);
  }

  @action
  deleteBlock(id) {
    if (this.blocks.length <= 1) return;
    const idx = this.blocks.findIndex((b) => b.id === id);
    const prev = this.blocks[idx - 1];
    this.blocks = this.blocks.filter((b) => b.id !== id);
    if (prev) { this.activeBlockId = prev.id; this._focusBlock(prev.id); }
    this._sync();
  }

  @action
  convertBlock(id, newType) {
    this.blocks = this.blocks.map((b) => b.id === id ? { ...b, type: newType } : b);
    this.slashMenuBlockId = null;
    this._focusBlock(id);
    this._sync();
  }

  @action
  handleKeydown(blockId, e) {
    const block = this.blocks.find((b) => b.id === blockId);
    if (!block) return;

    if (e.key === "Enter" && !e.shiftKey && block.type !== "quote") {
      e.preventDefault();
      this.slashMenuBlockId = null;
      this.addBlockAfter(blockId);
    } else if (e.key === "Backspace" && !block.content && block.type === "paragraph") {
      e.preventDefault();
      this.deleteBlock(blockId);
    } else if (e.key === "Escape") {
      this.slashMenuBlockId = null;
      this.toolbarBlockId = null;
    } else if (e.key === "/" && !block.content) {
      e.preventDefault();
      this.slashMenuBlockId = blockId;
    } else if (e.key === "ArrowUp" && e.altKey) {
      e.preventDefault();
      this._moveBlock(blockId, -1);
    } else if (e.key === "ArrowDown" && e.altKey) {
      e.preventDefault();
      this._moveBlock(blockId, 1);
    } else if ((e.metaKey || e.ctrlKey) && e.key === "b") {
      e.preventDefault(); this._wrapSelection(blockId, "**", "**");
    } else if ((e.metaKey || e.ctrlKey) && e.key === "i") {
      e.preventDefault(); this._wrapSelection(blockId, "*", "*");
    } else if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault();
      const url = prompt(i18n(themePrefix("composer.link_prompt")));
      if (url) this._wrapSelection(blockId, "[", `](${url})`);
    } else if (this.slashMenuBlockId === blockId && e.key !== "/") {
      this.slashMenuBlockId = null;
    }
  }

  @action
  handleFocus(blockId) {
    this.activeBlockId = blockId;
    this.toolbarBlockId = null;
    this._emitStatus();
  }

  @action
  handleSelect(blockId) {
    const ta = this._textarea(blockId);
    this.toolbarBlockId = ta && ta.selectionStart !== ta.selectionEnd ? blockId : null;
  }

  @action
  insertFromSlash(type) {
    if (this.slashMenuBlockId) this.convertBlock(this.slashMenuBlockId, type);
  }

  @action
  closeSlash() { this.slashMenuBlockId = null; }

  @action
  wrapInBlock(blockId, prefix, suffix) { this._wrapSelection(blockId, prefix, suffix); }

  @action
  toggleSource() {
    this.sourceMode = !this.sourceMode;
    this.args.onSourceModeChange?.(this.sourceMode);
  }

  // ── Internal ──────────────────────────────────────────────────

  _textarea(blockId) {
    return document.querySelector(`.fomio-cm-block[data-block-id="${blockId}"] textarea`);
  }

  _focusBlock(id) {
    Promise.resolve().then(() => {
      const el = this._textarea(id);
      if (!el) return;
      el.focus();
      const len = el.value.length;
      el.setSelectionRange(len, len);
      this._autoResize(el);
    });
  }

  _autoResize(el) {
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${el.scrollHeight}px`;
  }

  _moveBlock(id, dir) {
    const idx = this.blocks.findIndex((b) => b.id === id);
    const next = idx + dir;
    if (next < 0 || next >= this.blocks.length) return;
    const arr = [...this.blocks];
    [arr[idx], arr[next]] = [arr[next], arr[idx]];
    this.blocks = arr;
    this._sync();
  }

  _wrapSelection(blockId, prefix, suffix) {
    const ta = this._textarea(blockId);
    if (!ta) return;
    const { selectionStart: s, selectionEnd: e } = ta;
    const block = this.blocks.find((b) => b.id === blockId);
    if (!block) return;
    const selected = block.content.slice(s, e);
    const newContent = block.content.slice(0, s) + prefix + selected + suffix + block.content.slice(e);
    this.blocks = this.blocks.map((b) => b.id === blockId ? { ...b, content: newContent } : b);
    this._sync();
    Promise.resolve().then(() => {
      const el = this._textarea(blockId);
      if (el) { el.focus(); el.setSelectionRange(s + prefix.length, e + prefix.length); }
    });
  }

  _sync() {
    const md = this.serialized;
    try { this.composer.model?.set?.("reply", md); } catch { /* ignore */ }
    this.args.onMarkdownChange?.(md);
    this._emitStatus();
  }

  _emitStatus() {
    this.args.onStatusChange?.({
      words:            this.words,
      chars:            this.chars,
      readingMinutes:   this.readingMinutes,
      outlineItems:     this.outlineItems,
      activeBlockIndex: this.activeBlockIndex,
      totalBlocks:      this.blocks.length,
      sourceMode:       this.sourceMode,
    });
  }

  <template>
    <div class="fomio-cm-editor" role="region" aria-label={{i18n (themePrefix "composer.editor_label")}}>
      <div class="fomio-cm-gutter-track" aria-hidden="true">
        <span class="fomio-cm-gutter-line"></span>
      </div>

      <div class="fomio-cm-blocks">
        {{#each this.blocks as |block idx|}}
          <div class="fomio-cm-block-wrapper">
            <FomioBlock
              @blockData={{block}}
              @isCurrent={{eq block.id this.activeBlockId}}
              @isFirst={{eq idx 0}}
              @showSource={{this.sourceMode}}
              @onEdit={{this.editBlock}}
              @onKeydown={{this.handleKeydown}}
              @onFocus={{this.handleFocus}}
              @onSelect={{this.handleSelect}}
              @onAddAfter={{this.addBlockAfter}}
            />

            {{#if (eq block.id this.slashMenuBlockId)}}
              <div class="fomio-cm-slash" role="listbox" aria-label={{i18n (themePrefix "composer.slash_head")}}>
                <div class="fomio-cm-slash-head">{{i18n (themePrefix "composer.slash_head")}}</div>
                {{#each SLASH_ITEMS as |item|}}
                  <button
                    type="button"
                    role="option"
                    class="fomio-cm-slash-item{{if item.enabled '' ' is-disabled'}}"
                    disabled={{unless item.enabled true}}
                    {{on "click" (fn this.insertFromSlash item.type)}}
                  >
                    <span class="fomio-cm-slash-ico">
                      <SlashIcon @type={{item.type}} />
                    </span>
                    <span class="fomio-cm-slash-text">
                      <span class="fomio-cm-slash-name">{{item.label}}</span>
                      <span class="fomio-cm-slash-desc">{{item.desc}}</span>
                    </span>
                    {{#if item.hint}}
                      <span class="fomio-cm-slash-key">{{item.hint}}</span>
                    {{/if}}
                  </button>
                {{/each}}
              </div>
            {{/if}}

            {{#if (eq block.id this.toolbarBlockId)}}
              <FomioFloatingToolbar @onWrap={{fn this.wrapInBlock block.id}} />
            {{/if}}
          </div>
        {{/each}}
      </div>

      {{#if this.sourceMode}}
        <div class="fomio-cm-source-panel" aria-label={{i18n (themePrefix "composer.source_label")}}>
          <pre class="fomio-cm-source-pre">{{this.serialized}}</pre>
        </div>
      {{/if}}
    </div>
  </template>
}

export { serializeBlocks, parseMarkdownToBlocks, countWords, countChars };
