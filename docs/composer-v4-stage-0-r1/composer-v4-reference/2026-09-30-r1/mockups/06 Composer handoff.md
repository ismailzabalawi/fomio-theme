# Composer — design handoff (v4 r1, awaiting approval)

**Status: design only. Not approved, not locked, not for implementation.** No Discourse theme, component or core change has been made or should be made from this document until you approve and lock the design.

Companion files: `06 Composer.dc.html` (review: section index, IA and state axes, named frames, coverage), `06.1 Composer Prototype.dc.html` (one interactive prototype with simulation controls), `FmComposer4.dc.html` + `fmc4-lib.js` (shared prototype frame and fixtures; `FmComposer4` imports `FmHeader.dc.html` and `FmBottomNav.dc.html`, which are part of any frozen reference). Preserved for comparison: v3 (`06 Composer v3`, `06.1 Composer Prototype v3`, `06 Composer handoff v3.md`, `FmComposer3`), v2 and v1.

Evidence base: `uploads/09-composer-research.md`, `uploads/10-composer-ia-map.md`, `uploads/composer-design-context.md`, `uploads/composer-network-observations.csv`, `uploads/about.json`. Discourse 2026.8.0-latest, commit 7b4f0970. "Observed" means seen on the live site on 2026-09-28. "Source" means present in core at that commit but not exercised. Everything else is proposed.

## 1. Boundary (unchanged)

One continuous native composer. Discourse keeps the composer service, d-editor (rich text and Markdown), drafts and draft sequences, Uppy uploads, Onebox, poll, validation, reply/edit semantics, `POST /posts`, `PUT /posts/:id`, `PUT /t/:id`. No block editor, no new stored format, no replacement persistence or publishing engine, no local draft store. Tags and AI stay out (disabled). Uploads are images only (authorized extensions observed).

## 2. What v4 adds to v3

The Photo / Format / More hierarchy is unchanged. v4 adds named frames and working prototype routes for:

1. **Tablets** (TAB-1…11): 834×1194, 1194×834, split 600, split 375; software and hardware keyboard.
2. **Links** (C07-1…7): paste → preview loading → loaded / unsupported / fetch failed; hyperlink insert, edit, remove, cancel.
3. **Quote** (C10-1…6): reply to topic, reply to person, quoted reply, second quote, publish.
4. **Drafts** (C12-1…5 and C12-7…9, C15-1…3; C12-6 is unused, C12-7 = M5 and C12-8 = M5b are aliases): saving, saved, failed, offline, close during save, resume; draft changed elsewhere vs post edit conflict.
5. **Permissions** (C13-4/5/6, C19-1…5, L1/L2): category revoked, reply permission revoked, topic closed while writing, session expiry, accurate group audience.
6. **Advanced** (C08-1…12): table, details, date, spoiler, code, poll with validation and edit; conditional tools; mentions.
7. **Completion** (C16-1…5, C13-2/3, C17; C13-1 = M6 and C14-1 = M6b are aliases): busy with double-submit prevention, published, edit saved, error, rejection, approval.
8. **Guided form** (C18-1…5): conditional on category form templates.
9. **Upload** (C06-1…9): picker cancel, multi-select, paste, drop, partial failure, alt text, submit and mode switch while uploading, unauthorized file.
10. **Accessibility and stress** (A-1…6): focus, zoom, large text, mixed direction, RTL, long names, reduced motion.

## 3. State model

Independent axes. Changing one never resets another.

| Axis | Values | Rule |
|---|---|---|
| Layout | phone 360/390, split 375, split 600, tablet portrait, tablet landscape, desktop | Rotation or split change keeps text, caret, selection, uploads, open panel |
| Intent | new, reply to topic, reply to person, edit, edit first post | Reply as linked topic converts a reply to new, keeping text and adding a link back |
| Editor mode | rich text, Markdown | Switch blocked while any upload or link preview is pending |
| Keyboard/panels | software open/hidden, hardware, Format, More, link, alt, mentions, sheets, dialogs | See §4 |
| Draft | none, saving, saved, failed, offline, changed elsewhere; post edit conflict | Never shows "saved" unless saved |
| Upload (per image) | uploading n%, done, failed | Independent per image |
| Submission | idle, submitting, published, edit saved, pending, failed(offline, rate, rejected, error, conflict, permission, closed, session) | Every failure returns to the editor with content intact |

## 4. Layout rules (all proposed, unvalidated on devices)

| Rule | Phone | Tablet | Desktop | Narrow split |
|---|---|---|---|---|
| Composer | Full height | Portrait: docked sheet, top 330px, page visible. Landscape: docked 880px centred; auto full height while the software keyboard is up. Always full height below 700px wide. Fullscreen button when not auto. | Docked; fullscreen on request | Full height |
| Primary action | Top right | Top right in every variant (rotation never moves it) | Bottom right with draft status | Top right |
| Format / link / alt / mentions | Tray above strip, keyboard stays | Same; content max 560px | Same | Same |
| More | Takes keyboard slot | Popover above strip, keyboard stays | Popover | Keyboard slot |
| Sheets, dialogs | Bottom sheets | Centred form sheets 540px | Centred | Bottom sheets |
| Markdown preview | Inline toggle | Side by side at ≥1000px landscape, else inline | Side by side | Inline |
| Caret | Kept ≥16px above strip | Same; scroll area ends at strip | Native | Same |
| Safe areas | status 47 / home 34 | status 24 / home 20 | — | status 24 / home 20 |
| Hardware keyboard | — | No drawn keyboard, no Hide keyboard, Esc minimizes, native shortcuts | Native | Same as tablet |

Open question: whether Discourse serves its mobile or desktop view to a given tablet. The tablet layout is designed independently of that switch and must not be implemented as a scaled desktop layout.

## 5. Behaviour by case: native evidence vs proposal

| Case | Native evidence | Proposed | Recovery |
|---|---|---|---|
| Standalone URL preview | `GET /onebox` observed for a public URL | Loading placeholder; fetch-failure note with Try again (note never posted) | Link kept exactly as pasted; unsupported stays a plain link with no error |
| Inline link / hyperlink | Insert link (core `composer.link_dialog_title`) | Contextual strip: Edit link, Remove link | Cancel restores selection and caret |
| Quote | Quote button and `[quote="user, post:n, topic:id"]` are native; not exercised in research | Quote block card with author; second quote from page while minimized/docked | Remove quote block; Save and close keeps draft |
| Reply to person vs topic | `reply_to_post_number` (source) | Context row: topic title only vs person + expandable post | — |
| Draft save | `POST /drafts.json` observed; `draft_sequence`, `force_save` params (source) | Close waits during saving; Retry save; Copy text | Never closes over an unsaved draft |
| Offline | Not exercised | Composer stays open; saves on reconnect; Copy text | No local persistence invented |
| Draft changed elsewhere | Sequence checks exist (source); client UX not observed | Banner with Copy my text, Save mine over it (maps to `force_save`), Use the other version (`GET /drafts/:key`, confirm first) | Nothing replaced until the user chooses |
| Post edit conflict | 409 on stale edit (source); Overwrite Edit (core `composer.overwrite_edit`) | Keep editing (proposed copy) alongside Overwrite Edit | — |
| Category permission revoked | Guardian checks (source); not exercised | Names the category; Choose another category lists only permitted ones | Text kept |
| Reply permission revoked (C13-6) | Guardian checks (source); not exercised; Reply as linked topic is native | Banner "You can no longer reply here." with Reply as linked topic and Copy text | Reply kept |
| Topic closed while writing | Closed topics reject replies (source); Reply as linked topic is a native composer action | Banner explains; offers Reply as linked topic, Copy text | Text moves into new topic with "Continuing the discussion from" link |
| Session expired | Native login modal | Banner, Log In, then resubmit manually | Text kept in window; draft saves after login |
| Double submit | Composer has a saving state (source) | Action shows spinner, aria-busy; editor read-only; repeat taps ignored | — |
| Edit saved | `PUT /posts/:id` (source) | Return to edited post, highlighted with edit marker; "Edit saved" announced | — |
| Advanced inserts | Poll enabled (observed); table builder and local-dates builder are native modals; details/spoiler/code insert templates directly | Insert/edit/cancel sheets for all six, with validation | Cancel leaves content unchanged; Edit reopens prefilled |
| Conditional tools | `poll_enabled` observed; local-dates availability unconfirmed | Absent tools are not shown (never greyed) | — |
| Mentions | `GET /u/search/users` with `include_groups` observed | Loading, results, no results, keyboard selection, Esc dismiss | Typing continues after dismiss |
| Guided form | `enable_form_templates`, `show_preview_for_form_templates` observed on; no category known to use one; not exercised | Template choice, required errors, preview, category switch moves answers into text | Answers never dropped on switch |
| Uploads | `POST /uploads` (source); images only (observed) | Multi-select picker, per-image progress, Cancel, Retry, Remove, partial failure | Other images unaffected; submit and mode switch wait |
| Alt text | Alt lives in image Markdown (native) | Alt text action on a selected image | Cancel keeps previous alt |

## 6. Copy status

**Observed:** New Byte, Create topic, Type title, or paste a link here, Create Topic, Byte, Reply, Why are you editing?, Save Edit, Cancel edit, Save and close, Minimize the composer panel, Discard, Do you want to discard your post?, Markdown placeholder, Options.

**Core wording (verified in Discourse locale files at 7b4f0970; key in brackets). The mockup shows it verbatim:** Markdown [composition_mode.markdown], Saving [composer.saving], Your topic is similar to… [composer.similar_topics], Search… [select_kit.filter_placeholder], No matches found [select_kit.no_content], Uploading… [composer.uploading], Cancel [composer.cancel], Insert link / Edit link [composer.link_dialog_title / link_edit_title], Link text [composer.link_text_label], OK [composer.modal_ok], Build poll [poll.ui_builder.title], Insert Poll [poll.ui_builder.insert], Single Choice / Multiple Choice [poll.ui_builder.poll_type.*], Options (one per line) [poll.ui_builder.poll_options.label], Enter at least 1 option. [poll.ui_builder.help.options_min_count], Poll must have different options. [poll server default_poll_must_have_different_options], Insert table [composer.insert_table], Hide details [details.title], Insert date / time [discourse_local_dates.title], Blur spoiler [spoiler.title], Preformatted text [composer.code_title], Overwrite Edit [composer.overwrite_edit], Post Needs Approval + We've received your new post… [review.approval.title / description], You have 1 post pending. [review.approval.pending_posts], Log In, Sign Up [log_in, sign_up], Try Again [errors.buttons.again], Sorry, an error has occurred. [generic_error], rate-limit message [rate_limiter.too_many_requests], is too similar to what you recently posted [just_posted_that], Title is required, Title must be at least %{count} characters, Post must be at least %{count} characters [composer.error.*], Please fill out this field. [form_templates.errors.value_missing.default], unauthorized-file message [post.errors.upload_not_authorized], Quote [post.quote_reply], Reply as linked topic [composer.composer_actions.reply_as_new_topic.label], Continuing the discussion from [post.continue_discussion], Drafts, Resume [drafts.label, drafts.resume], Paragraph, Heading [composer.heading_level_paragraph, heading_text], Do you want to discard your changes? + Discard changes [post.cancel_composer.confirm_edit / discard_edit], begin composing a reply to this post, edit this post [post.controls.reply / edit], Discard [post.cancel_composer.discard].

**Shown as fixtures but differing from core (production renders the core key; the mockup keeps the fixture on purpose):** Draft saved (persistent status; core only has the toast "Draft saved!" [composer.draft_saved]), Edit conflict (core renders "edit conflict" [composer.edit_conflict]), Category (core category.choose "Category…"), "Search categories" as the chooser search field's accessible name (the placeholder is core "Search…"), edit marker (core shows an icon; "edited" is notifications.titles.edited), This topic is closed… (topic page notice; core topic_statuses.locked.help reads "This topic is closed; it no longer accepts new replies").

**Previously listed as core but not in core at 7b4f0970. Now classified as proposed copy (see D-group choices):** Keep editing, Save draft for later (the native discard dialog offers Discard and Cancel), Unable to connect. (core network error: "Network Error" / "Please check your connection."), Searching… (mention loading).

**Proposed copy (needs an i18n key or site-text override before shipping):** Photo, Format, More (or override of Options: decision D2), Bold/Italic/Bullets/Numbers/Quote/Link visible labels, Subheading, Public, "[Groups] only", Add edit reason, Hide keyboard, Edit link, Remove link, Alt text, Remove, Edit, Describe the photo, Writing in rich text / Writing in Markdown source / Finish or remove uploads first, Upload failed / … was not added., Drop images to upload, Preview unavailable. The link will be posted as written., Try again (preview), Wait for the photos to finish uploading., Offline. Draft not saved, Draft not saved, You're offline. Draft not saved. + body, Draft not saved. + bodies, Retry save, Copy text, Copy my text, This draft changed somewhere else. + body, Save mine over it, Use the other version, Replace your text with the other version? + body, Replace, You can no longer post in [category]. + body, Choose another category, [category] is no longer available to you…, You can no longer reply here. + body, This topic was closed while you were writing. + body, You were logged out. + body, Not posted. / Not posted yet. titles, Switch to [category]? + bodies, Switch and keep answers/text, Add (n), Summary, Hidden text, Text to blur, Code, Language, Timezone, Date, Time, Options (one per line), Add row, Add column, Add at least one column heading., Add a summary., Choose a date., Add the text to blur., Add the code or text to preformat., Suggestions, Edit saved, Text copied, Simulated keyboard (prototype only, never shipped).

Form field labels and options (What stage is it at?, Your piece, etc.) are category configuration fixtures, not UI copy.

## 7. Accessibility behaviour (designed; validation pending)

- **Focus order:** Save and close → Minimize → Fullscreen (tablet) → primary action → destination → title → similar topics → body → notices → open panel → tool strip → Hide keyboard. Desktop: primary action last.
- **Visible focus:** 2px accent outline, 2px offset. Writing area shows its caret instead.
- **Escape / Back:** mention list → quote button → sheet or dialog → panel → selected block → (desktop or hardware keyboard) minimize. Android Back follows the same order (proposed).
- **Focus restoration:** closing a sheet returns focus to its trigger, or to the saved caret. Submit errors focus the first invalid field. Dialogs focus their safe action first. Focus trapping inside dialogs is specified but not built in the prototype.
- **Announcements:** one polite live region for draft state changes (not each save), upload results, preview result, suggestion count, submit result. Banners role=alert.
- **Dialog roles:** ordinary sheets and dialogs (destination, More, inserts, photo, pending approval, log in, form switch) use role=dialog with a labelled heading; only destructive confirmations (discard, replace text) use role=alertdialog.
- **Targets:** 44px minimum on touch.
- **Zoom / large text:** reflows at 150% and 200%. Below 330 CSS px, strip and draft status become icons with accessible names (as built; the large-text status treatment LT is pending review — unsaved, offline, failed and conflict states may need to stay readable).
- **Direction:** logical properties mirror the interface; each paragraph, title and answer takes its own direction (`unicode-bidi: plaintext`, `dir=auto`).
- **Reduced motion:** transitions and spinners stop; status text still changes.

## 8. Remaining product decisions

- **D1** Tablet: approve docked-in-portrait and auto-full-height-in-landscape, or always full height on tablets.
- **D2** "More" as new key vs override of observed "Options".
- **D3** Draft changed elsewhere: approve all three actions, or only Copy my text + Use the other version (drop force save).
- **D4** Offline close: keep blocking close, or allow close with an explicit "Lose unsaved changes" confirmation.
- **D5** Guided form category switch: move answers into text (proposed) vs block switching once answers exist.
- **D6** Details, spoiler, code: approve insert sheets, or keep the native direct-template insert with the placeholder selected.
- **D7** Link-preview failure note: keep, or rely on the plain link alone as native does.
- **D8** Whether to ship any guided form at all before a real category is configured.
- **D9** Emoji toolbar button: hide via toolbar config or keep under More (no-emoji UI rule).
- **D10** Session expiry: manual resubmit after login (proposed) vs automatic resubmit.

## 9. Feasibility items (theme seams to prove before committing)

(a) = verified seam in research; (b) = feasibility prototype needed; (c) = plugin. Nothing here is established as (c); nothing is claimed as themeable without evidence.

- (a) Layout, spacing, type, surfaces via CSS on native composer markup.
- (a) Photo one-tap (native upload button), Options popup menu items, core dialogs, drafts list, pending approval.
- (b) Photo / Format / More grouping over d-editor toolbar (`api.onToolbarCreate`, `addComposerToolbarPopupMenuOption`), in both modes, with shortcuts intact.
- (b) Contextual strip (selection, link, image, block) from ProseMirror and textarea selection without experimental node APIs.
- (b) Tablet docked/auto-full-height behaviour around `#reply-control` resizer and `visualViewport`.
- (b) Inline upload progress/retry/remove next to Uppy placeholders; multi-select and partial failure.
- (b) Link-preview failure note; plain-link fallback behaviour for unsupported URLs.
- (b) Inline banners for draft failure, draft conflict, permission and closed-topic errors via `addComposerSaveErrorCallback` and draft error handling.
- (b) Close-wait-for-save and offline close blocking against native close behaviour.
- (b) Insert/edit sheets for details, spoiler, code; editing existing blocks in the rich editor.
- (b) Form-template field model, preview composition format and category-switch behaviour.
- (b) Outlet allowlist: any composer outlet must be added to `docs/03-implementation.md` and `scripts/check-duplication.sh`.

## 10. Device and assistive-technology validation (not done)

- iOS Safari and Android Chrome: keyboard height, `visualViewport` resize, whether `pointerdown` preventDefault keeps the keyboard up for Format and More, safe areas, native selection handles vs the Quote button, iPad hardware keyboard and trackpad, Stage Manager and split-view transitions, rotation with an open upload.
- VoiceOver, TalkBack, NVDA: labels, live-region verbosity, focus order, dialogs, listbox for mentions.
- Platform text scaling (Dynamic Type, Android font scale); browser zoom was only simulated by CSS zoom.
- Real translated string lengths; real category and group names.

## 11. What was checked in the prototype (browser simulation only, 2026-09-30)

These checks ran on the revision before r1. After r1 the frames were re-rendered and inspected (see §12), but the scripted interaction checks were not re-run.

Scripted in Chrome with DOM assertions:
- Tablet rotation portrait → landscape → split 600 with two uploads in progress: text kept, uploads completed (3 images, 0 failures), layout changed.
- Links: paste → card; unsupported → plain link; failure → note → Try again → card; original text kept. Edit link panel prefilled; Cancel kept link and returned focus to the text; Remove link kept text; insert on a selection wrapped exactly "slow mornings"; URL field focused.
- Quote: Quote from Ravi's post opened a reply to Ravi with `[quote="ravi, post:2, topic:4127"]`; minimized; selected text in Maya's post; second quote added; published post contained 2 quotes and the reply text. Topic reply had no person context; person reply showed "Reply to Ravi Patel".
- Drafts: close during a slow save waited, then closed and listed the draft. Save failure showed a banner; close blocked; Retry save then closed. Offline close blocked; going online saved and cleared the banner ("Draft saved. You can close now."); close then worked. Draft changed elsewhere: no autosave while unresolved; Use the other version opened a confirm with focus on Keep editing; Keep editing returned focus to the text with the edit intact; Save mine over it saved.
- Permissions: revoked category banner; Choose another category focused search and omitted the revoked category; resubmit published. Topic closed while writing → Reply as linked topic kept the reply and added the link; focus moved to title. Session expired → Log In → banner cleared, draft saved, text kept; resubmit published.
- Completion: double tap on Create Topic produced one published topic. Edit saved returned to the topic with the edited post highlighted, edit marker and new text. Server error → Try Again published.
- Advanced: More listed all six tools; poll duplicate options error; valid poll inserted; selecting the block showed Edit | Remove | More; Edit prefilled; Cancel left it unchanged. Table (added row → 2 columns, 3 rows), date, details (empty summary error). Mentions: results listed users and a group; no-results state; Esc dismissed.
- Upload: picker Cancel inserted nothing and returned focus to the text; three selected → Add (3) → three uploading; submit blocked with message; Markdown switch blocked; every-second-fails produced one failure; Retry succeeded; alt text saved into the image Markdown; dropping a PDF showed the unauthorized message; dropping 2 images started 2 uploads.
- Guided form: empty submit showed two required errors; preview rendered headings from answers; switching to Open Discussions showed the confirm and moved answers into the body; valid form published with headings.

Visually inspected (screenshots) at 390×844, 360×740, split 375×834, split 600×834, 834×1194, 1194×834, 1280×800, light and AMOLED, LTR and RTL, 150% and 200% zoom. Fixed during review: destination path wrapping; More popover horizontal overflow; status text clipping at 150% (now icon with accessible name below 330px).

**Not verified:** any Discourse integration; real keyboards and devices; screen readers; focus trapping in dialogs; production rich-editor rendering of inserted blocks (the prototype shows summary cards); network timing. Mention pick via real keyboard events is scripted with synthetic events only.

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

