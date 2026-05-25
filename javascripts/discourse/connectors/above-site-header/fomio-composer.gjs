import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn, concat } from "@ember/helper";
import { service } from "@ember/service";
import { getOwner } from "@ember/owner";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import Composer from "discourse/models/composer";
import FomioBlockEditor from "../../components/fomio-block-editor";
import FomioButton from "../../components/shared/fomio-button";

// ── Icons ─────────────────────────────────────────────────────

const IcoBack = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6" /></svg>
</template>;

const IcoSource = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 4l-5 8 5 8M15 4l5 8-5 8" /></svg>
</template>;

const IcoClose = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" /></svg>
</template>;

const IcoArrow = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 5l7 7-7 7" /></svg>
</template>;

const IcoEdit = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 20h4l11-11-4-4L4 16zM14 5l4 4" /></svg>
</template>;

const IcoPlus = <template>
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 5v14M5 12h14" /></svg>
</template>;

const IcoCheck = <template>
  <svg viewBox="0 0 24 24" width="10" height="10" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 12 4 4L19 7" /></svg>
</template>;

const IcoChev = <template>
  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9l6 6 6-6" /></svg>
</template>;

const IcoHome = <template>
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12l9-9 9 9M5 10v10h14V10" /></svg>
</template>;

const IcoLatest = <template>
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18M3 12h12M3 18h18" /></svg>
</template>;

// ── Sidebar ───────────────────────────────────────────────────

class FomioComposerSidebar extends Component {
  @service currentUser;

  get initial() { return (this.currentUser?.username?.[0] ?? "").toUpperCase(); }
  get name()    { return this.currentUser?.name || this.currentUser?.username || ""; }
  get handle()  { return `@${this.currentUser?.username ?? ""}`; }

  <template>
    <aside class="fomio-cm-sidebar">
      <div class="fomio-cm-sb-brand">
        <span class="fomio-cm-sb-wordmark">fomio</span>
      </div>

      <div class="fomio-cm-sb-section">
        <div class="fomio-cm-sb-row fomio-cm-sb-row--primary" aria-current="true">
          <IcoPlus />
          <span>{{i18n (themePrefix "sidebar.create_byte")}}</span>
        </div>
        <a href="/latest" class="fomio-cm-sb-row">
          <IcoHome />
          <span>{{i18n (themePrefix "sidebar.home")}}</span>
        </a>
        <a href="/latest" class="fomio-cm-sb-row">
          <IcoLatest />
          <span>Latest</span>
        </a>
      </div>

      {{#if @draftTitle}}
        <div class="fomio-cm-sb-section">
          <div class="fomio-cm-sb-label">{{i18n (themePrefix "composer.sidebar_draft")}}</div>
          <div class="fomio-cm-sb-row fomio-cm-sb-row--active">
            <span class="fomio-cm-sb-dot"></span>
            <span class="fomio-cm-sb-draft-title">{{@draftTitle}}</span>
          </div>
        </div>
      {{/if}}

      <div class="fomio-cm-sb-spacer"></div>

      {{#if this.currentUser}}
        <div class="fomio-cm-sb-foot">
          <span class="fomio-cm-sb-av" aria-hidden="true">{{this.initial}}</span>
          <div class="fomio-cm-sb-id">
            <span class="fomio-cm-sb-name">{{this.name}}</span>
            <span class="fomio-cm-sb-handle">{{this.handle}}</span>
          </div>
        </div>
      {{/if}}
    </aside>
  </template>
}

// ── Topbar ────────────────────────────────────────────────────

class ComposerHeader extends Component {
  get modeLabel() {
    switch (this.args.mode) {
      case "reply": return i18n(themePrefix("composer.mode_reply"));
      case "edit":  return i18n(themePrefix("composer.mode_edit"));
      default:      return i18n(themePrefix("composer.mode_create"));
    }
  }

  get backLabel() {
    return this.args.mode === "create"
      ? (this.args.categoryName || i18n(themePrefix("sidebar.home")))
      : i18n(themePrefix("composer.back"));
  }

  <template>
    <div class="fomio-cm-topbar">
      <button type="button" class="fomio-cm-back" {{on "click" @onClose}}>
        <IcoBack />
        <span>{{this.backLabel}}</span>
      </button>
      <div class="fomio-cm-mode">
        {{i18n (themePrefix "composer.mode_label")}} · <b>{{this.modeLabel}}</b>
      </div>
      <div class="fomio-cm-topbar-right">
        <button type="button" class="fomio-cm-icon-btn{{if @sourceMode ' is-active' ''}}" title={{i18n (themePrefix "composer.source_toggle")}} aria-label={{i18n (themePrefix "composer.source_toggle")}} aria-pressed={{@sourceMode}} {{on "click" @onToggleSource}}>
          <IcoSource />
        </button>
        <button type="button" class="fomio-cm-icon-btn" title={{i18n (themePrefix "composer.close")}} aria-label={{i18n (themePrefix "composer.close")}} {{on "click" @onClose}}>
          <IcoClose />
        </button>
      </div>
    </div>
  </template>
}

// ── Meta fields ───────────────────────────────────────────────

class ComposerMetaFields extends Component {
  @action onTitleInput(e) { this.args.onTitleChange?.(e.target.value); }

  <template>
    <header class="fomio-cm-header">
      {{! autofocus moves keyboard focus into the dialog when it opens (WCAG 2.4.3) }}
      <input
        class="fomio-cm-title-input"
        type="text"
        value={{@title}}
        placeholder={{i18n (themePrefix "composer.title_placeholder")}}
        maxlength="255"
        autofocus
        {{on "input" this.onTitleInput}}
      />
      <div class="fomio-cm-meta-row">
        <button type="button" class="fomio-cm-teret-trigger">
          {{#if @categoryName}}
            <span class="fomio-cm-teret-hub">{{@categoryName}}</span>
            <span class="fomio-cm-teret-swatch"></span>
            <span class="fomio-cm-teret-label">{{@subcategoryName}}</span>
          {{else}}
            <span class="fomio-cm-teret-placeholder">{{i18n (themePrefix "composer.choose_teret")}}</span>
          {{/if}}
          <span class="fomio-cm-teret-chev"><IcoChev /></span>
        </button>
      </div>
    </header>
  </template>
}

// ── Right rail ────────────────────────────────────────────────

class FomioComposerRail extends Component {
  get wordBarWidth() {
    return `${Math.min(100, ((this.args.words || 0) / 1200) * 100)}%`;
  }
  get titleOk()  { return !!(this.args.title?.trim()); }
  get teretOk()  { return !!(this.args.categoryId); }

  <template>
    <aside class="fomio-cm-rail">
      {{#if (eq @mode "edit")}}
        <div class="fomio-cm-rail-section">
          <h4>{{i18n (themePrefix "composer.rail_revision")}}</h4>
          <div class="fomio-cm-rail-meta-label">{{i18n (themePrefix "composer.rail_editing")}}</div>
        </div>
      {{else}}
        <div class="fomio-cm-rail-section">
          <h4>{{i18n (themePrefix "composer.rail_draft")}}</h4>
          <div class="fomio-cm-rail-meter">
            <div class="fomio-cm-rail-stats">
              <div class="fomio-cm-rail-stat">
                <b>{{@words}}</b>
                <span>{{i18n (themePrefix "composer.words")}}</span>
              </div>
              <div class="fomio-cm-rail-stat">
                <b>{{@readingMinutes}} {{i18n (themePrefix "composer.min")}}</b>
                <span>{{i18n (themePrefix "composer.read")}}</span>
              </div>
            </div>
            <div class="fomio-cm-rail-bar">
              <div class="fomio-cm-rail-bar-fill" style={{concat "width:" this.wordBarWidth}}></div>
            </div>
            <div class="fomio-cm-rail-hint">{{i18n (themePrefix "composer.word_range")}}</div>
          </div>
        </div>
      {{/if}}

      {{#if @outlineItems.length}}
        <div class="fomio-cm-rail-section">
          <h4>{{i18n (themePrefix "composer.rail_outline")}}</h4>
          <div class="fomio-cm-rail-outline">
            {{#each @outlineItems as |item|}}
              <button
                type="button"
                class="fomio-cm-rail-out fomio-cm-rail-out--{{item.level}}"
                {{on "click" (fn @onScrollToBlock item.id)}}
              >{{item.text}}</button>
            {{/each}}
          </div>
        </div>
      {{/if}}

      {{#if (eq @mode "create")}}
        <div class="fomio-cm-rail-section">
          <h4>{{i18n (themePrefix "composer.rail_checks")}}</h4>
          <div class="fomio-cm-rail-checks">
            <span class="fomio-cm-check{{if this.titleOk ' is-ok' ''}}">
              {{#if this.titleOk}}<IcoCheck />{{/if}}
              {{i18n (themePrefix "composer.check_title")}}
            </span>
            <span class="fomio-cm-check{{if this.teretOk ' is-ok' ''}}">
              {{#if this.teretOk}}<IcoCheck />{{/if}}
              {{i18n (themePrefix "composer.check_teret")}}
            </span>
            <span class="fomio-cm-check{{if @hasMinContent ' is-ok' ''}}">
              {{#if @hasMinContent}}<IcoCheck />{{/if}}
              {{i18n (themePrefix "composer.check_length")}}
            </span>
          </div>
        </div>
      {{/if}}
    </aside>
  </template>
}

// ── Status bar ────────────────────────────────────────────────

class FomioComposerStatusBar extends Component {
  <template>
    <div class="fomio-cm-status-bar" aria-hidden="true">
      <span class="fomio-cm-status-seg fomio-cm-status-seg--ok">
        <IcoCheck />
        {{i18n (themePrefix "composer.status_draft_saved")}}
      </span>
      <span class="fomio-cm-status-sep" aria-hidden="true">·</span>
      <span class="fomio-cm-status-seg">{{@words}} {{i18n (themePrefix "composer.words")}} · {{@chars}} {{i18n (themePrefix "composer.chars")}}</span>
      <span class="fomio-cm-status-sep" aria-hidden="true">·</span>
      <span class="fomio-cm-status-seg">{{i18n (themePrefix "composer.status_block")}} {{@activeBlockIndex}} / {{@totalBlocks}}</span>
      <div class="fomio-cm-status-right">
        <span class="fomio-cm-status-seg">{{if @sourceMode (i18n (themePrefix "composer.status_markdown")) (i18n (themePrefix "composer.status_rendered"))}}</span>
      </div>
    </div>
  </template>
}

// ── Actions row ───────────────────────────────────────────────

class ComposerActions extends Component {
  get publishLabel() {
    switch (this.args.mode) {
      case "reply": return i18n(themePrefix("composer.action_reply"));
      case "edit":  return i18n(themePrefix("composer.action_save_changes"));
      default:      return i18n(themePrefix("composer.action_publish"));
    }
  }
  get shortcutHint() {
    switch (this.args.mode) {
      case "reply": return i18n(themePrefix("composer.shortcut_send"));
      case "edit":  return i18n(themePrefix("composer.shortcut_save"));
      default:      return i18n(themePrefix("composer.shortcut_publish"));
    }
  }

  <template>
    <div class="fomio-cm-submit">
      <div class="fomio-cm-submit-hints">
        <span><kbd class="fomio-cm-key">⌘</kbd><kbd class="fomio-cm-key">↵</kbd> {{this.shortcutHint}}</span>
        <span><kbd class="fomio-cm-key">/</kbd> {{i18n (themePrefix "composer.hint_blocks")}}</span>
        <span><kbd class="fomio-cm-key">esc</kbd> {{i18n (themePrefix "composer.hint_close")}}</span>
      </div>
      <FomioButton
        @variant="ghost"
        @extraClass="fomio-cm-btn fomio-cm-btn--tertiary"
        {{on "click" @onClose}}
      >
        {{i18n (themePrefix "composer.cancel")}}
      </FomioButton>
      {{#if (eq @mode "create")}}
        <FomioButton
          @variant="secondary"
          @extraClass="fomio-cm-btn fomio-cm-btn--secondary"
          {{on "click" @onSaveDraft}}
        >
          {{i18n (themePrefix "composer.save_draft")}}
        </FomioButton>
      {{/if}}
      <FomioButton
        @variant="primary"
        @size="lg"
        @isLoading={{@isSaving}}
        @extraClass="fomio-cm-btn fomio-cm-btn--primary"
        {{on "click" @onPublish}}
      >
        {{this.publishLabel}} <IcoArrow />
      </FomioButton>
    </div>

    <div class="fomio-cm-mobile-bar">
      <FomioButton
        @variant="ghost"
        @extraClass="fomio-cm-btn fomio-cm-btn--tertiary"
        style="height:36px;padding:0 12px"
        {{on "click" @onClose}}
      >
        {{i18n (themePrefix "composer.cancel")}}
      </FomioButton>
      <FomioButton
        @variant="primary"
        @size="lg"
        @block={{true}}
        @isLoading={{@isSaving}}
        @extraClass="fomio-cm-btn fomio-cm-btn--primary"
        style="flex:1;height:44px"
        {{on "click" @onPublish}}
      >
        {{this.publishLabel}}
      </FomioButton>
    </div>
  </template>
}

// ── Reply context ─────────────────────────────────────────────

const ReplyContext = <template>
  {{#if @post}}
    <article class="fomio-cm-reply-ctx">
      <div class="fomio-cm-reply-ctx-meta">
        <span class="fomio-cm-reply-ctx-author">{{@post.username}}</span>
        <span class="fomio-cm-reply-ctx-dot">·</span>
        <span>{{@post.topic.title}}</span>
      </div>
      <h2 class="fomio-cm-reply-ctx-title">{{@post.topic.title}}</h2>
      <p class="fomio-cm-reply-ctx-excerpt">{{@post.excerpt}}</p>
    </article>
  {{/if}}
</template>;

// ── Edit banner ───────────────────────────────────────────────

const EditBanner = <template>
  <div class="fomio-cm-edit-banner">
    <div class="fomio-cm-edit-banner-ico"><IcoEdit /></div>
    <div class="fomio-cm-edit-banner-txt">
      <b>{{i18n (themePrefix "composer.edit_banner_title")}}</b>
      <span>{{i18n (themePrefix "composer.edit_banner_subtitle")}}</span>
    </div>
  </div>
</template>;

// ── Breadcrumbs ───────────────────────────────────────────────

const ComposerCrumbs = <template>
  <div class="fomio-cm-crumbs" aria-label="breadcrumb">
    {{#if @categoryName}}
      <span>{{@categoryName}}</span>
      <span class="fomio-cm-crumbs-sep" aria-hidden="true">/</span>
    {{/if}}
    <span>{{i18n (themePrefix "composer.crumb_drafts")}}</span>
    <span class="fomio-cm-crumbs-sep" aria-hidden="true">/</span>
    <span class="fomio-cm-crumbs-here">
      {{if @title @title (i18n (themePrefix "composer.crumb_new_byte"))}}
    </span>
  </div>
</template>;

// ── Main shell ────────────────────────────────────────────────

class FomioComposerShell extends Component {
  @service composer;
  @service currentUser;
  @service appEvents;

  @tracked _isOpen = false;
  @tracked title = "";
  @tracked sourceMode = false;
  @tracked isSaving = false;
  @tracked editorStatus = { words: 0, chars: 0, readingMinutes: 1, outlineItems: [], activeBlockIndex: 0, totalBlocks: 1, sourceMode: false };

  constructor(owner, args) {
    super(owner, args);
    // composer.isOpen is an Ember computed, not @tracked — subscribe via appEvents instead
    this.appEvents.on("composer:opened", this, "_onComposerOpen");
    this.appEvents.on("composer:closed", this, "_onComposerClose");
    this.appEvents.on("composer:cancelled", this, "_onComposerClose");
  }

  willDestroy() {
    super.willDestroy();
    this.appEvents.off("composer:opened", this, "_onComposerOpen");
    this.appEvents.off("composer:closed", this, "_onComposerClose");
    this.appEvents.off("composer:cancelled", this, "_onComposerClose");
  }

  @action _onComposerOpen() {
    this._isOpen = true;
    this._syncTitle();
  }

  @action _onComposerClose() {
    this._isOpen = false;
    this.isSaving = false;
  }

  _syncTitle() {
    this.title = this.composer.model?.title || "";
  }

  get isOpen() { return this._isOpen; }

  get model() { return this.composer.model; }

  get mode() {
    const a = this.model?.action;
    if (a === Composer.REPLY)        return "reply";
    if (a === Composer.EDIT)         return "edit";
    return "create";
  }

  get categoryName() {
    return this.model?.category?.name || "";
  }

  get subcategoryName() {
    return this.model?.subcategory?.name || this.categoryName;
  }

  get categoryId() { return this.model?.categoryId; }

  get replyPost() { return this.model?.post; }

  get replyInitial() {
    return (this.currentUser?.username?.[0] ?? "").toUpperCase();
  }

  get hasMinContent() {
    return (this.editorStatus.chars || 0) >= 280;
  }

  get draftTitle() {
    return this.title || this.model?.title || "";
  }

  // ── Actions ───────────────────────────────────────────────────

  @action
  onTitleChange(value) {
    this.title = value;
    try { this.model?.set?.("title", value); } catch { /* ignore */ }
  }

  @action
  onMarkdownChange() {
    // model.reply already updated by FomioBlockEditor; nothing extra needed here
  }

  @action
  onStatusChange(status) {
    this.editorStatus = status;
    if (status.sourceMode !== undefined) {
      this.sourceMode = status.sourceMode;
    }
  }

  @action
  onSourceModeChange(val) {
    this.sourceMode = val;
  }

  @action
  onToggleSource() {
    this.sourceMode = !this.sourceMode;
  }

  @action
  onClose() {
    this.isSaving = false;
    this.composer.close();
  }

  @action
  onPublish() {
    if (this.isSaving) return;
    this.isSaving = true;

    // Strategy 1: use composer controller send action
    try {
      const composerController = getOwner(this).lookup("controller:composer");
      if (composerController?.send) {
        composerController.send("save");
        // composer will close on success, which clears isOpen
        setTimeout(() => { this.isSaving = false; }, 4000);
        return;
      }
    } catch { /* fall through */ }

    // Strategy 2: click the hidden native submit button
    const submitBtn = document.querySelector("#reply-control .btn-primary, #reply-control button[type='submit']");
    if (submitBtn) {
      submitBtn.click();
    }

    setTimeout(() => { this.isSaving = false; }, 4000);
  }

  @action
  onSaveDraft() {
    // Discourse auto-saves on model.reply changes; show flash feedback
    const seg = document.querySelector(".fomio-cm-status-seg--ok");
    if (seg) { seg.classList.add("is-flash"); setTimeout(() => seg.classList.remove("is-flash"), 800); }
  }

  @action
  onScrollToBlock(blockId, e) {
    e?.preventDefault();
    const el = document.querySelector(`.fomio-cm-block[data-block-id="${blockId}"]`);
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
    el?.querySelector("textarea")?.focus();
  }

  @action
  onShellKeydown(e) {
    if (e.key === "Escape" && !e.defaultPrevented) {
      e.preventDefault();
      this.onClose();
    } else if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      this.onPublish();
    }
  }

  <template>
    {{#if this.isOpen}}
      <div
        class="fomio-cm-overlay"
        role="dialog"
        aria-modal="true"
        aria-label={{i18n (themePrefix "composer.dialog_label")}}
        {{on "keydown" this.onShellKeydown}}
      >
        <div class="fomio-cm-shell">

          <FomioComposerSidebar @draftTitle={{this.draftTitle}} />

          <main class="fomio-cm-main">

            <ComposerHeader
              @mode={{this.mode}}
              @categoryName={{this.categoryName}}
              @sourceMode={{this.sourceMode}}
              @onClose={{this.onClose}}
              @onToggleSource={{this.onToggleSource}}
            />

            <div class="fomio-cm-scroll-area">

              {{! ── Reply mode ── }}
              {{#if (eq this.mode "reply")}}
                <div class="fomio-cm-page fomio-cm-page--reply">
                  <ReplyContext @post={{this.replyPost}} />

                  <div class="fomio-cm-reply-card is-focused">
                    <div class="fomio-cm-reply-head">
                      <span class="fomio-cm-reply-av" aria-hidden="true">{{this.replyInitial}}</span>
                      <div class="fomio-cm-reply-who">
                        {{this.currentUser.name}}
                        {{#if this.replyPost}}
                          <span class="fomio-cm-reply-ctx-line">
                            {{i18n (themePrefix "composer.replying_to")}}
                            <b>@{{this.replyPost.username}}</b>
                          </span>
                        {{/if}}
                      </div>
                    </div>

                    <div class="fomio-cm-reply-body">
                      <FomioBlockEditor
                        @onMarkdownChange={{this.onMarkdownChange}}
                        @onStatusChange={{this.onStatusChange}}
                        @onSourceModeChange={{this.onSourceModeChange}}
                      />
                    </div>

                    <div class="fomio-cm-reply-foot">
                      <div class="fomio-cm-reply-tools">
                        <span class="fomio-cm-reply-wordcount">
                          {{this.editorStatus.words}} {{i18n (themePrefix "composer.words")}} · ⌘↵ to send
                        </span>
                      </div>
                      <div class="fomio-cm-reply-actions">
                        <FomioButton
                          @variant="ghost"
                          @extraClass="fomio-cm-btn fomio-cm-btn--tertiary"
                          style="height:36px;padding:0 14px"
                          {{on "click" this.onClose}}
                        >
                          {{i18n (themePrefix "composer.cancel")}}
                        </FomioButton>
                        <FomioButton
                          @variant="primary"
                          @isLoading={{this.isSaving}}
                          @extraClass="fomio-cm-btn fomio-cm-btn--primary"
                          style="height:36px;padding:0 18px"
                          {{on "click" this.onPublish}}
                        >
                          {{i18n (themePrefix "composer.action_reply")}}
                        </FomioButton>
                      </div>
                    </div>
                  </div>

                  <div class="fomio-cm-discourse-note">
                    <span class="fomio-cm-note-dot" aria-hidden="true"></span>
                    {{i18n (themePrefix "composer.discourse_note")}}
                  </div>
                </div>

              {{else}}
                {{! ── Create + Edit mode ── }}
                <div class="fomio-cm-page fomio-cm-page--create">

                  {{#if (eq this.mode "edit")}}
                    <EditBanner />
                  {{else}}
                    <ComposerCrumbs
                      @categoryName={{this.categoryName}}
                      @title={{this.title}}
                    />
                  {{/if}}

                  <div class="fomio-cm-with-rail">
                    <div class="fomio-cm-main-col">
                      <ComposerMetaFields
                        @title={{this.title}}
                        @categoryName={{this.categoryName}}
                        @subcategoryName={{this.subcategoryName}}
                        @onTitleChange={{this.onTitleChange}}
                      />

                      <FomioBlockEditor
                        @onMarkdownChange={{this.onMarkdownChange}}
                        @onStatusChange={{this.onStatusChange}}
                        @onSourceModeChange={{this.onSourceModeChange}}
                      />
                    </div>

                    <FomioComposerRail
                      @mode={{this.mode}}
                      @words={{this.editorStatus.words}}
                      @chars={{this.editorStatus.chars}}
                      @readingMinutes={{this.editorStatus.readingMinutes}}
                      @outlineItems={{this.editorStatus.outlineItems}}
                      @title={{this.title}}
                      @categoryId={{this.categoryId}}
                      @hasMinContent={{this.hasMinContent}}
                      @onScrollToBlock={{this.onScrollToBlock}}
                    />
                  </div>

                  <ComposerActions
                    @mode={{this.mode}}
                    @isSaving={{this.isSaving}}
                    @onClose={{this.onClose}}
                    @onPublish={{this.onPublish}}
                    @onSaveDraft={{this.onSaveDraft}}
                  />
                </div>
              {{/if}}

            </div>

            <FomioComposerStatusBar
              @words={{this.editorStatus.words}}
              @chars={{this.editorStatus.chars}}
              @activeBlockIndex={{this.editorStatus.activeBlockIndex}}
              @totalBlocks={{this.editorStatus.totalBlocks}}
              @sourceMode={{this.sourceMode}}
            />

          </main>
        </div>
      </div>
    {{/if}}
  </template>
}

// ── Connector export ──────────────────────────────────────────

export default class FomioComposerConnector extends Component {
  @service composer;

  <template></template>
}
