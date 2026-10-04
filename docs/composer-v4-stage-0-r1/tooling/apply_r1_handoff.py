import sys,os
p=os.path.join(sys.argv[1],"mockups/06 Composer handoff.md"); s=open(p,encoding="utf-8").read()
def rep(old,new,n=1):
    global s; c=s.count(old); assert c==n,(old[:60],c); s=s.replace(old,new)
rep("# Composer — design handoff (v4, awaiting approval)","# Composer — design handoff (v4 r1, awaiting approval)")
rep("`FmComposer4.dc.html` + `fmc4-lib.js` (shared prototype frame and fixtures).",
    "`FmComposer4.dc.html` + `fmc4-lib.js` (shared prototype frame and fixtures; `FmComposer4` imports `FmHeader.dc.html` and `FmBottomNav.dc.html`, which are part of any frozen reference).")
rep("1. **Tablets** (TAB-1…10):","1. **Tablets** (TAB-1…11):")
rep("4. **Drafts** (C12-1…9, C15-1…3):","4. **Drafts** (C12-1…5 and C12-7…9, C15-1…3; C12-6 is unused, C12-7 = M5 and C12-8 = M5b are aliases):")
rep("5. **Permissions** (C13-4/5, C19-1…5, L1/L2): category revoked,","5. **Permissions** (C13-4/5/6, C19-1…5, L1/L2): category revoked, reply permission revoked,")
rep("7. **Completion** (C16-1…5, C13-2/3, C17):","7. **Completion** (C16-1…5, C13-2/3, C17; C13-1 = M6 and C14-1 = M6b are aliases):")
rep("| Inline link / hyperlink | Insert Hyperlink (core) |","| Inline link / hyperlink | Insert link (core `composer.link_dialog_title`) |")
rep("| Post edit conflict | 409 on stale edit (source); Overwrite Edits (core wording) | Keep editing alongside Overwrite Edits | — |",
    "| Post edit conflict | 409 on stale edit (source); Overwrite Edit (core `composer.overwrite_edit`) | Keep editing (proposed copy) alongside Overwrite Edit | — |")
rep("| Category permission revoked | Guardian checks (source); not exercised | Names the category; Choose another category lists only permitted ones | Text kept |",
    "| Category permission revoked | Guardian checks (source); not exercised | Names the category; Choose another category lists only permitted ones | Text kept |\n| Reply permission revoked (C13-6) | Guardian checks (source); not exercised; Reply as linked topic is native | Banner \"You can no longer reply here.\" with Reply as linked topic and Copy text | Reply kept |")
old6_start=s.index("**Core fixtures (default wording shown, not observed on this site):**")
old6_end=s.index("**Proposed copy (needs an i18n key or site-text override before shipping):**")
new_core=("**Core wording (verified in Discourse locale files at 7b4f0970; key in brackets). The mockup shows it verbatim:** "
"Markdown [composition_mode.markdown], Saving [composer.saving], Your topic is similar to… [composer.similar_topics], Search… [select_kit.filter_placeholder], No matches found [select_kit.no_content], "
"Uploading… [composer.uploading], Cancel [composer.cancel], Insert link / Edit link [composer.link_dialog_title / link_edit_title], Link text [composer.link_text_label], OK [composer.modal_ok], "
"Build poll [poll.ui_builder.title], Insert Poll [poll.ui_builder.insert], Single Choice / Multiple Choice [poll.ui_builder.poll_type.*], Options (one per line) [poll.ui_builder.poll_options.label], "
"Enter at least 1 option. [poll.ui_builder.help.options_min_count], Poll must have different options. [poll server default_poll_must_have_different_options], "
"Insert table [composer.insert_table], Hide details [details.title], Insert date / time [discourse_local_dates.title], Blur spoiler [spoiler.title], Preformatted text [composer.code_title], "
"Overwrite Edit [composer.overwrite_edit], Post Needs Approval + We've received your new post… [review.approval.title / description], You have 1 post pending. [review.approval.pending_posts], "
"Log In, Sign Up [log_in, sign_up], Try Again [errors.buttons.again], Sorry, an error has occurred. [generic_error], rate-limit message [rate_limiter.too_many_requests], "
"is too similar to what you recently posted [just_posted_that], Title is required, Title must be at least %{count} characters, Post must be at least %{count} characters [composer.error.*], "
"Please fill out this field. [form_templates.errors.value_missing.default], unauthorized-file message [post.errors.upload_not_authorized], Quote [post.quote_reply], "
"Reply as linked topic [composer.composer_actions.reply_as_new_topic.label], Continuing the discussion from [post.continue_discussion], Drafts, Resume [drafts.label, drafts.resume], "
"Paragraph, Heading [composer.heading_level_paragraph, heading_text], Do you want to discard your changes? + Discard changes [post.cancel_composer.confirm_edit / discard_edit], "
"begin composing a reply to this post, edit this post [post.controls.reply / edit], Discard [post.cancel_composer.discard].\n\n"
"**Shown as fixtures but differing from core (production renders the core key; the mockup keeps the fixture on purpose):** Draft saved (persistent status; core only has the toast \"Draft saved!\" [composer.draft_saved]), "
"Edit conflict (core renders \"edit conflict\" [composer.edit_conflict]), Category (core category.choose \"Category…\"), \"Search categories\" as the chooser search field's accessible name (the placeholder is core \"Search…\"), "
"edit marker (core shows an icon; \"edited\" is notifications.titles.edited), This topic is closed… (topic page notice; core topic_statuses.locked.help reads \"This topic is closed; it no longer accepts new replies\").\n\n"
"**Previously listed as core but not in core at 7b4f0970. Now classified as proposed copy (see D-group choices):** Keep editing, Save draft for later (the native discard dialog offers Discard and Cancel), Unable to connect. (core network error: \"Network Error\" / \"Please check your connection.\"), Searching… (mention loading).\n\n")
s=s[:old6_start]+new_core+s[old6_end:]
rep("- **Announcements:** one polite live region for draft state changes (not each save), upload results, preview result, suggestion count, submit result. Banners role=alert; dialogs alertdialog with labelled heading.",
    "- **Announcements:** one polite live region for draft state changes (not each save), upload results, preview result, suggestion count, submit result. Banners role=alert.\n- **Dialog roles:** ordinary sheets and dialogs (destination, More, inserts, photo, pending approval, log in, form switch) use role=dialog with a labelled heading; only destructive confirmations (discard, replace text) use role=alertdialog.")
rep("- **Zoom / large text:** reflows at 150% and 200%. Below 330 CSS px, strip and draft status become icons with accessible names.",
    "- **Zoom / large text:** reflows at 150% and 200%. Below 330 CSS px, strip and draft status become icons with accessible names (as built; the large-text status treatment LT is pending review — unsaved, offline, failed and conflict states may need to stay readable).")
rep("## 11. What was checked in the prototype (browser simulation only, 2026-09-30)\n",
    "## 11. What was checked in the prototype (browser simulation only, 2026-09-30)\n\nThese checks ran on the revision before r1. After r1 the frames were re-rendered and inspected (see §12), but the scripted interaction checks were not re-run.\n")
s=s.rstrip("\n")+"""

## 12. Revision r1 (2026-09-30): audit corrections

Mechanical and factual corrections from the Stage 0 audit (repo docs 14 I-1…I-12 and 15 A1–A10). No product decision (D1–D10, LT) and no intentional Section C/D wording choice was settled.

| Audit | Change |
|---|---|
| A1, I-8 | Native surfaces now show verified core wording: Saving, Insert link, Link text, Search… (placeholder), Build poll, Insert date / time, Single Choice / Multiple Choice, Overwrite Edit, Discard changes (edit discard), approval body, Please fill out this field. §5 and §6 reclassified; strings not in core are now marked proposed. |
| A2 | Poll builder rule follows core: at least 1 option ("Enter at least 1 option."); duplicates show "Poll must have different options." Whether duplicates are caught in the builder or only by the server on submit is unverified (stage 1). |
| A3 | Keep editing and Save draft for later are no longer claimed as core. They stay in the design as proposed copy (see pending P-1). |
| A4, I-1 | TAB-9 is the tablet destination sheet everywhere; the uploads-during-rotation state is new TAB-11 (frame and prototype route). |
| A5, I-2, I-3 | C12-6 is recorded as unused. Aliases are explicit: C12-7 = M5, C12-8 = M5b, C13-1 = M6, C14-1 = M6b. |
| A6, I-9 | The existing noReply banner is framed as C13-6 (reply permission revoked) with a preset and prototype route. |
| A7, I-12 | Presets with a selection scroll it into view within the writing area (kept ≥16px above the tray/strip), so M3 and C07-6 show the selection they keep. |
| A8, I-4 | role=alertdialog only for discard and replace-text; other dialogs use role=dialog. |
| A9, I-11 | FmHeader and FmBottomNav are listed as FmComposer4 dependencies; any frozen reference must include them. |
| A10, I-10 | `screenshots/v4-a.png` (JPEG data) renamed to `screenshots/v4-a.jpg`. Other screenshot formats were not checked. |
| I-5 | The review page now states that the draft status, not only the strip, becomes icon-only below 330 CSS px (LT pending). |
| I-6 | tokens/core-variables.css and mockups/README.md explain that "Source Sans 3" is the preview name of Source Sans Pro, the Discourse base_font setting. |

**Pending choices recorded during r1 (not decided):**
- **P-1 Discard dialog actions.** Native offers Discard and Cancel. v4 offers Keep editing, Save draft for later and Discard. Options: (a) adopt the native two actions, (b) keep v4's three actions as proposed copy. Left as (b) pending.
- **P-2 Offline submit banner title.** Options: (a) core "Network Error" / "Please check your connection.", (b) keep proposed "Unable to connect." Left as (b) pending (Section D, submission outcomes).
- **P-3 Persistent draft-status wording.** Core has only a transient "Draft saved!" toast and "drafts offline". The persistent "Draft saved" / "Draft not saved" / "Offline. Draft not saved" status stays proposed, and is tied to D4 and LT.
- **P-4 Destination search accessible name.** "Search categories" (proposed) vs the core placeholder "Search…" as the only label.
"""
open(p,"w",encoding="utf-8").write(s+"\n")
print("handoff updated")
