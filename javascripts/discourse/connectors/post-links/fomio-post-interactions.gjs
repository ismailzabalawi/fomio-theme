import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { eq, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Composer from "discourse/models/composer";
import FlagModal from "discourse/components/modal/flag";
import PostFlag from "discourse/lib/flag-targets/post-flag";
import FomioButton from "../../components/shared/fomio-button";
import FomioAvatar from "../../components/shared/fomio-avatar";
import { redirectToLoginWithIntent } from "../../lib/fomio-auth-intent";

// ── SVG icon helpers ─────────────────────────────────────────

const IcoHeart = <template>
  {{#if @filled}}
    <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
      <path fill="currentColor" d="M12 20.5S4.5 15.9 2.5 11.3C1.1 7.7 3.4 4.5 6.7 4.5c2 0 3.5 1 4.3 2.4.2.4.7.4.9 0 .8-1.4 2.3-2.4 4.3-2.4 3.3 0 5.6 3.2 4.2 6.8C19.5 15.9 12 20.5 12 20.5Z" />
    </svg>
  {{else}}
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M12 20.5S4.5 15.9 2.5 11.3C1.1 7.7 3.4 4.5 6.7 4.5c2 0 3.5 1 4.3 2.4.2.4.7.4.9 0 .8-1.4 2.3-2.4 4.3-2.4 3.3 0 5.6 3.2 4.2 6.8C19.5 15.9 12 20.5 12 20.5Z" />
    </svg>
  {{/if}}
</template>;

const IcoChat = <template>
  <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M21 11.5a8.5 8.5 0 0 1-12.9 7.3L3 20l1.3-4.4A8.5 8.5 0 1 1 21 11.5Z" />
  </svg>
</template>;

const IcoBookmark = <template>
  {{#if @filled}}
    <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
      <path fill="currentColor" d="M6 3.5h12a1 1 0 0 1 1 1V21l-7-4-7 4V4.5a1 1 0 0 1 1-1Z" />
    </svg>
  {{else}}
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M6 3.5h12a1 1 0 0 1 1 1V21l-7-4-7 4V4.5a1 1 0 0 1 1-1Z" />
    </svg>
  {{/if}}
</template>;

const IcoShare = <template>
  <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M12 14V4m0 0-3.5 3.5M12 4l3.5 3.5M5 13v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5" />
  </svg>
</template>;

const IcoCheck = <template>
  <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="m5 12 5 5L20 7" />
  </svg>
</template>;

const IcoMore = <template>
  <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
    <circle cx="5"  cy="12" r="1.5" fill="currentColor" />
    <circle cx="12" cy="12" r="1.5" fill="currentColor" />
    <circle cx="19" cy="12" r="1.5" fill="currentColor" />
  </svg>
</template>;

const IcoReply = <template>
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M9 17 4 12l5-5M4 12h11a5 5 0 0 1 5 5v3" />
  </svg>
</template>;

const IcoHeartSm = <template>
  {{#if @filled}}
    <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
      <path fill="currentColor" d="M12 20.5S4.5 15.9 2.5 11.3C1.1 7.7 3.4 4.5 6.7 4.5c2 0 3.5 1 4.3 2.4.2.4.7.4.9 0 .8-1.4 2.3-2.4 4.3-2.4 3.3 0 5.6 3.2 4.2 6.8C19.5 15.9 12 20.5 12 20.5Z" />
    </svg>
  {{else}}
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M12 20.5S4.5 15.9 2.5 11.3C1.1 7.7 3.4 4.5 6.7 4.5c2 0 3.5 1 4.3 2.4.2.4.7.4.9 0 .8-1.4 2.3-2.4 4.3-2.4 3.3 0 5.6 3.2 4.2 6.8C19.5 15.9 12 20.5 12 20.5Z" />
    </svg>
  {{/if}}
</template>;

// ── Shared mixin: dismissable menu ───────────────────────────
// Adds click-outside and Escape-key dismissal to a component
// that tracks menuOpen state.

class WithDismissMenu extends Component {
  _outsideHandler = null;

  openMenu(containerRef) {
    this.menuOpen = true;
    this._outsideHandler = (e) => {
      if (containerRef && !containerRef.contains(e.target)) {
        this.closeMenu();
      }
    };
    // Defer so the current click doesn't immediately dismiss
    setTimeout(() => {
      document.addEventListener("mousedown", this._outsideHandler);
    }, 0);
  }

  @action
  closeMenu() {
    this.menuOpen = false;
    if (this._outsideHandler) {
      document.removeEventListener("mousedown", this._outsideHandler);
      this._outsideHandler = null;
    }
  }

  willDestroy() {
    super.willDestroy();
    if (this._outsideHandler) {
      document.removeEventListener("mousedown", this._outsideHandler);
    }
  }
}

// ── 1. Byte toolbar (post #1) ─────────────────────────────────

class FomioByteToolbar extends WithDismissMenu {
  @service currentUser;
  @service composer;
  @service modal;

  @tracked liked = false;
  @tracked likeCount = 0;
  @tracked bookmarked = false;
  @tracked shared = false;
  @tracked menuOpen = false;

  moreRef = null;

  constructor(owner, args) {
    super(owner, args);
    const post = args.post;
    this.liked = post?.likeAction?.acted ?? false;
    this.likeCount = post?.likeAction?.count ?? 0;
    this.bookmarked = post?.bookmarked ?? false;
  }

  get post() {
    return this.args.post;
  }

  get commentCount() {
    return this.post?.topic?.reply_count ?? 0;
  }

  get canEdit() {
    return this.post?.can_edit ?? false;
  }

  get canDelete() {
    return this.post?.can_delete ?? false;
  }

  get isMod() {
    return this.currentUser?.staff ?? false;
  }

  get shareUrl() {
    const topicId = this.post?.topicId ?? this.post?.topic_id;
    const slug = this.post?.topic?.slug;
    if (slug && topicId) {
      return `${window.location.origin}/t/${slug}/${topicId}`;
    }
    return window.location.href;
  }

  @action
  async toggleLike() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("save_interact_bytes", window.location.pathname);
      return;
    }
    const wasLiked = this.liked;
    this.liked = !wasLiked;
    this.likeCount = wasLiked
      ? Math.max(0, this.likeCount - 1)
      : this.likeCount + 1;
    try {
      if (wasLiked) {
        await ajax(`/post_actions/${this.post.id}`, {
          type: "DELETE",
          data: { post_action_type_id: 2 },
        });
      } else {
        await ajax("/post_actions", {
          type: "POST",
          data: { id: this.post.id, post_action_type_id: 2, flag_topic: false },
        });
      }
    } catch (e) {
      this.liked = wasLiked;
      this.likeCount = wasLiked
        ? this.likeCount + 1
        : Math.max(0, this.likeCount - 1);
      popupAjaxError(e);
    }
  }

  @action
  jumpToComments() {
    const anchor = document.getElementById("fomio-discussion");
    if (anchor) anchor.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  @action
  async toggleBookmark() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("save_interact_bytes", window.location.pathname);
      return;
    }
    const wasBookmarked = this.bookmarked;
    this.bookmarked = !wasBookmarked;
    try {
      if (wasBookmarked && this.post.bookmark_id) {
        await ajax(`/bookmarks/${this.post.bookmark_id}`, { type: "DELETE" });
      } else {
        await ajax("/bookmarks", {
          type: "POST",
          data: {
            bookmarkable_id: this.post.id,
            bookmarkable_type: "Post",
          },
        });
      }
    } catch (e) {
      this.bookmarked = wasBookmarked;
      popupAjaxError(e);
    }
  }

  @action
  async share() {
    const url = this.shareUrl;
    try {
      if (navigator.share) {
        await navigator.share({ title: document.title, url });
      } else if (navigator.clipboard) {
        await navigator.clipboard.writeText(url);
      }
    } catch { /* user cancelled */ }
    this.shared = true;
    setTimeout(() => (this.shared = false), 1800);
  }

  @action
  toggleMenu(e) {
    if (this.menuOpen) {
      this.closeMenu();
    } else {
      this.openMenu(e.currentTarget.closest(".fomio-byte-secondary-actions"));
    }
  }

  @action
  handleMenuKeydown(e) {
    if (e.key === "Escape") this.closeMenu();
  }

  @action
  copyLink() {
    if (navigator.clipboard) navigator.clipboard.writeText(this.shareUrl);
    this.closeMenu();
  }

  @action
  openCompose() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("join_discussion", window.location.pathname);
      return;
    }
    this.composer.open({
      action: Composer.REPLY,
      topic: this.post.topic,
      draftKey: this.post.topic?.draft_key ?? `topic_${this.post.topic?.id ?? this.post.topic_id}`,
    });
  }

  @action
  editPost() {
    this.closeMenu();
    this.composer.open({
      action: Composer.EDIT,
      post: this.post,
      draftKey: this.post.topic?.draft_key ?? `topic_${this.post.topic?.id ?? this.post.topic_id}`,
      draftSequence: this.post.topic?.draft_sequence,
    });
  }

  @action
  async deletePost() {
    this.closeMenu();
    try {
      await ajax(`/posts/${this.post.id}`, { type: "DELETE" });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  _topicId() {
    return this.post.topic?.id ?? this.post.topic_id;
  }

  async _setTopicStatus(status, enabled) {
    this.closeMenu();
    try {
      await ajax(`/t/${this._topicId()}/status`, {
        type: "PUT",
        data: { status, enabled },
      });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action hidePost()    { return this._setTopicStatus("visible", false); }
  @action lockTopic()   { return this._setTopicStatus("closed", true); }
  @action pinTopic()    { return this._setTopicStatus("pinned", true); }
  @action archiveTopic(){ return this._setTopicStatus("archived", true); }

  @action
  reportPost() {
    this.closeMenu();
    this.modal.show(FlagModal, {
      model: {
        flagTarget: new PostFlag(),
        flagModel: this.post,
        setHidden: () => {},
      },
    });
  }

  <template>
    <nav
      class="fomio-byte-actions"
      aria-label={{i18n (themePrefix "byte_toolbar.aria_label")}}
    >
      <div class="fomio-byte-primary-actions">

        {{! Like }}
        <FomioButton
          @variant="ghost"
          @iconOnly={{true}}
          @isActive={{this.liked}}
          @extraClass="fomio-action like"
          aria-pressed={{this.liked}}
          aria-label={{i18n (themePrefix "byte_toolbar.like_label")}}
          data-tip={{i18n (themePrefix "byte_toolbar.like_tip")}}
          {{on "click" this.toggleLike}}
        >
          <IcoHeart @filled={{this.liked}} />
          {{#if this.likeCount}}
            <span class="fomio-action__count">{{this.likeCount}}</span>
          {{/if}}
        </FomioButton>

        {{! Comment / discussion jump }}
        <FomioButton
          @variant="ghost"
          @iconOnly={{true}}
          @extraClass="fomio-action comment has-count"
          aria-label={{i18n (themePrefix "byte_toolbar.comment_label") count=this.commentCount}}
          data-tip={{i18n (themePrefix "byte_toolbar.comment_tip")}}
          {{on "click" this.jumpToComments}}
        >
          <IcoChat />
          <span class="fomio-action__count">{{this.commentCount}}</span>
        </FomioButton>

        {{! Bookmark }}
        <FomioButton
          @variant="ghost"
          @iconOnly={{true}}
          @isActive={{this.bookmarked}}
          @extraClass="fomio-action bookmark"
          aria-pressed={{this.bookmarked}}
          aria-label={{if this.bookmarked
            (i18n (themePrefix "byte_toolbar.saved_label"))
            (i18n (themePrefix "byte_toolbar.bookmark_label"))
          }}
          data-tip={{if this.bookmarked
            (i18n (themePrefix "byte_toolbar.saved_tip"))
            (i18n (themePrefix "byte_toolbar.bookmark_tip"))
          }}
          {{on "click" this.toggleBookmark}}
        >
          <IcoBookmark @filled={{this.bookmarked}} />
        </FomioButton>

        {{! Share }}
        <FomioButton
          @variant="ghost"
          @iconOnly={{true}}
          @isActive={{this.shared}}
          @extraClass="fomio-action share"
          aria-label={{if this.shared
            (i18n (themePrefix "byte_toolbar.copied_label"))
            (i18n (themePrefix "byte_toolbar.share_label"))
          }}
          data-tip={{if this.shared
            (i18n (themePrefix "byte_toolbar.copied_tip"))
            (i18n (themePrefix "byte_toolbar.share_tip"))
          }}
          {{on "click" this.share}}
        >
          {{#if this.shared}}
            <IcoCheck />
          {{else}}
            <IcoShare />
          {{/if}}
        </FomioButton>

      </div>

      {{! More ⋯ }}
      <div
        class="fomio-byte-secondary-actions"
        {{on "keydown" this.handleMenuKeydown}}
      >
        <FomioButton
          @variant="ghost"
          @iconOnly={{true}}
          @isOpen={{this.menuOpen}}
          @extraClass="fomio-action more"
          aria-haspopup="menu"
          aria-expanded={{this.menuOpen}}
          aria-label={{i18n (themePrefix "byte_toolbar.more_label")}}
          data-tip={{i18n (themePrefix "byte_toolbar.more_tip")}}
          {{on "click" this.toggleMenu}}
        >
          <IcoMore />
        </FomioButton>

        {{#if this.menuOpen}}
          <div class="fomio-byte-more-menu" role="menu">
            {{#if this.canEdit}}
              <button type="button" role="menuitem" {{on "click" this.editPost}}>
                {{i18n (themePrefix "byte_toolbar.edit")}}
              </button>
            {{/if}}
            {{#if this.canDelete}}
              <button
                type="button"
                role="menuitem"
                class="is-destructive"
                {{on "click" this.deletePost}}
              >
                {{i18n (themePrefix "byte_toolbar.delete")}}
              </button>
            {{/if}}
            {{#if (or this.canEdit this.canDelete)}}
              <hr />
            {{/if}}
            {{#if this.isMod}}
              <button type="button" role="menuitem" {{on "click" this.hidePost}}>
                {{i18n (themePrefix "byte_toolbar.hide")}}
              </button>
              <button type="button" role="menuitem" {{on "click" this.lockTopic}}>
                {{i18n (themePrefix "byte_toolbar.lock")}}
              </button>
              <button type="button" role="menuitem" {{on "click" this.pinTopic}}>
                {{i18n (themePrefix "byte_toolbar.pin")}}
              </button>
              <button type="button" role="menuitem" {{on "click" this.archiveTopic}}>
                {{i18n (themePrefix "byte_toolbar.archive")}}
              </button>
              <hr />
            {{/if}}
            <button type="button" role="menuitem" {{on "click" this.copyLink}}>
              {{i18n (themePrefix "byte_toolbar.copy_link")}}
            </button>
            <button type="button" role="menuitem" {{on "click" this.reportPost}}>
              {{i18n (themePrefix "byte_toolbar.report")}}
            </button>
          </div>
        {{/if}}
      </div>
    </nav>
  </template>
}

// ── 2. Comment entry point ────────────────────────────────────

class FomioCommentEntry extends Component {
  @service currentUser;
  @service composer;

  get initial() {
    return (this.currentUser?.username?.[0] ?? "").toLowerCase();
  }

  @action
  openCompose() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("join_discussion", window.location.pathname);
      return;
    }
    this.args.onReply?.();
  }

  @action
  goToLogin(e) {
    e.preventDefault();
    redirectToLoginWithIntent("join_discussion", window.location.pathname);
  }

  get draftKey() {
    const topic = this.args.post?.topic;
    return topic?.draft_key ?? `topic_${topic?.id ?? "new"}`;
  }

  <template>
    {{#if this.currentUser}}
      <button
        type="button"
        class="fomio-comment-entry"
        aria-label={{i18n (themePrefix "comment_entry.aria_label")}}
        {{on "click" this.openCompose}}
      >
        <FomioAvatar
          @size="sm"
          @initials={{this.initial}}
          @extraClass="fomio-comment-entry__avatar"
        />
        <span class="fomio-comment-entry__placeholder">
          {{i18n (themePrefix "comment_entry.placeholder")}}
        </span>
      </button>
    {{else}}
      <a
        class="fomio-comment-entry is-guest"
        href="/login?fomio_web=1"
        role="button"
        {{on "click" this.goToLogin}}
      >
        <FomioAvatar
          @size="sm"
          @initials=""
          @extraClass="fomio-comment-entry__avatar is-empty"
        />
        <span class="fomio-comment-entry__placeholder">
          {{i18n (themePrefix "comment_entry.guest_placeholder")}}
        </span>
      </a>
    {{/if}}
  </template>
}

// ── 3. Comment actions (posts #2+) ────────────────────────────

class FomioCommentActions extends WithDismissMenu {
  @service currentUser;
  @service composer;
  @service modal;

  @tracked liked = false;
  @tracked likeCount = 0;
  @tracked menuOpen = false;

  constructor(owner, args) {
    super(owner, args);
    const post = args.post;
    this.liked = post?.likeAction?.acted ?? false;
    this.likeCount = post?.likeAction?.count ?? 0;
  }

  get post() {
    return this.args.post;
  }

  get canEdit() {
    return this.post?.can_edit ?? false;
  }

  get canDelete() {
    return this.post?.can_delete ?? false;
  }

  get shareUrl() {
    const topicId = this.post?.topicId ?? this.post?.topic_id;
    const postNumber = this.post?.post_number;
    const slug = this.post?.topic?.slug;
    if (slug && topicId && postNumber) {
      return `${window.location.origin}/t/${slug}/${topicId}/${postNumber}`;
    }
    return window.location.href;
  }

  @action
  async toggleLike() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("save_interact_bytes", window.location.pathname);
      return;
    }
    const wasLiked = this.liked;
    this.liked = !wasLiked;
    this.likeCount = wasLiked
      ? Math.max(0, this.likeCount - 1)
      : this.likeCount + 1;
    try {
      if (wasLiked) {
        await ajax(`/post_actions/${this.post.id}`, {
          type: "DELETE",
          data: { post_action_type_id: 2 },
        });
      } else {
        await ajax("/post_actions", {
          type: "POST",
          data: { id: this.post.id, post_action_type_id: 2, flag_topic: false },
        });
      }
    } catch (e) {
      this.liked = wasLiked;
      this.likeCount = wasLiked
        ? this.likeCount + 1
        : Math.max(0, this.likeCount - 1);
      popupAjaxError(e);
    }
  }

  @action
  reply() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("join_discussion", window.location.pathname);
      return;
    }
    this.composer.open({
      action: Composer.REPLY,
      post: this.post,
      topic: this.post.topic,
      draftKey: this.post.topic?.draft_key ?? `topic_${this.post.topic?.id ?? this.post.topic_id}`,
    });
  }

  @action
  toggleMenu(e) {
    if (this.menuOpen) {
      this.closeMenu();
    } else {
      this.openMenu(e.currentTarget.closest(".fomio-comment-actions__more"));
    }
  }

  @action
  handleMenuKeydown(e) {
    if (e.key === "Escape") this.closeMenu();
  }

  @action
  copyLink() {
    if (navigator.clipboard) navigator.clipboard.writeText(this.shareUrl);
    this.closeMenu();
  }

  @action
  editComment() {
    this.closeMenu();
    this.composer.open({
      action: Composer.EDIT,
      post: this.post,
      draftKey: this.post.topic?.draft_key ?? `topic_${this.post.topic?.id ?? this.post.topic_id}`,
      draftSequence: this.post.topic?.draft_sequence,
    });
  }

  @action
  async deleteComment() {
    this.closeMenu();
    try {
      await ajax(`/posts/${this.post.id}`, { type: "DELETE" });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  reportComment() {
    this.closeMenu();
    this.modal.show(FlagModal, {
      model: {
        flagTarget: new PostFlag(),
        flagModel: this.post,
        setHidden: () => {},
      },
    });
  }

  <template>
    <div class="fomio-comment-actions">
      {{! Like }}
      <FomioButton
        @variant="ghost"
        @iconOnly={{true}}
        @size="sm"
        @isActive={{this.liked}}
        @extraClass="fomio-action sm like"
        aria-pressed={{this.liked}}
        aria-label={{i18n (themePrefix "comment_actions.like_label")}}
        {{on "click" this.toggleLike}}
      >
        <IcoHeartSm @filled={{this.liked}} />
        {{#if this.likeCount}}
          <span class="fomio-action__count">{{this.likeCount}}</span>
        {{/if}}
      </FomioButton>

      {{! Reply }}
      <FomioButton
        @variant="ghost"
        @size="sm"
        @extraClass="fomio-action sm reply"
        aria-label={{i18n (themePrefix "comment_actions.reply_label")}}
        {{on "click" this.reply}}
      >
        <IcoReply />
        <span class="fomio-action__label">
          {{i18n (themePrefix "comment_actions.reply_text")}}
        </span>
      </FomioButton>

      {{! More ⋯ }}
      <div
        class="fomio-comment-actions__more"
        {{on "keydown" this.handleMenuKeydown}}
      >
        <FomioButton
          @variant="ghost"
          @iconOnly={{true}}
          @size="sm"
          @isOpen={{this.menuOpen}}
          @extraClass="fomio-action sm more"
          aria-haspopup="menu"
          aria-expanded={{this.menuOpen}}
          aria-label={{i18n (themePrefix "comment_actions.more_label")}}
          {{on "click" this.toggleMenu}}
        >
          <IcoMore />
        </FomioButton>

        {{#if this.menuOpen}}
          <div class="fomio-byte-more-menu is-end" role="menu">
            {{#if this.canEdit}}
              <button type="button" role="menuitem" {{on "click" this.editComment}}>
                {{i18n (themePrefix "byte_toolbar.edit")}}
              </button>
            {{/if}}
            {{#if this.canDelete}}
              <button
                type="button"
                role="menuitem"
                class="is-destructive"
                {{on "click" this.deleteComment}}
              >
                {{i18n (themePrefix "byte_toolbar.delete")}}
              </button>
            {{/if}}
            {{#if (or this.canEdit this.canDelete)}}
              <hr />
            {{/if}}
            <button type="button" role="menuitem" {{on "click" this.copyLink}}>
              {{i18n (themePrefix "byte_toolbar.copy_link")}}
            </button>
            <button type="button" role="menuitem" {{on "click" this.reportComment}}>
              {{i18n (themePrefix "byte_toolbar.report")}}
            </button>
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}

// ── Root connector ────────────────────────────────────────────

export default class FomioPostInteractions extends Component {
  @service currentUser;
  @service composer;

  get post() {
    return this.args.outletArgs?.post;
  }

  get isBytePost() {
    return this.post?.post_number === 1;
  }

  get isCommentPost() {
    return (this.post?.post_number ?? 0) > 1;
  }

  get discussionCount() {
    return this.post?.topic?.reply_count ?? 0;
  }

  @action
  openReply() {
    if (!this.currentUser) {
      redirectToLoginWithIntent("join_discussion", window.location.pathname);
      return;
    }
    this.composer.open({
      action: Composer.REPLY,
      topic: this.post.topic,
      draftKey: this.post.topic?.draft_key ?? `topic_${this.post.topic?.id ?? this.post.topic_id}`,
    });
  }

  <template>
    {{#if this.isBytePost}}
      {{! Primary toolbar }}
      <FomioByteToolbar @post={{this.post}} />

      {{! Endmark ◆ }}
      <div class="fomio-byte-endmark" aria-hidden="true">
        <span class="fomio-byte-endmark__glyph"></span>
      </div>

      {{! Discussion anchor + header + comment entry }}
      <section
        class="fomio-discussion fomio-comments"
        id="fomio-discussion"
        aria-label={{i18n (themePrefix "discussion.aria_label")}}
      >
        {{#if this.discussionCount}}
          <header class="fomio-discussion__header fomio-comments__header">
            <h2 class="fomio-discussion__title fomio-comments__title">
              {{i18n (themePrefix "discussion.title")}}
            </h2>
            <span class="fomio-discussion__count fomio-comments__count">
              {{this.discussionCount}}
              {{if (eq this.discussionCount 1)
                (i18n (themePrefix "discussion.reply_singular"))
                (i18n (themePrefix "discussion.reply_plural"))
              }}
            </span>
          </header>
        {{/if}}

        <FomioCommentEntry @onReply={{this.openReply}} />
      </section>

    {{else if this.isCommentPost}}
      {{! Comment post actions }}
      <FomioCommentActions @post={{this.post}} />
    {{/if}}
  </template>
}
