import sys,os
W=sys.argv[1]; log=[]
def edit(path, reps):
    p=os.path.join(W,path); s=open(p,encoding="utf-8").read()
    for old,new,n,tag in reps:
        c=s.count(old)
        assert c==n, f"{path}: expected {n} of {old[:70]!r}, found {c}"
        s=s.replace(old,new); log.append((path,tag,n))
    open(p,"w",encoding="utf-8").write(s)

# ---------- FmComposer4 ----------
edit("mockups/FmComposer4.dc.html",[
 ('<div data-sheet="" role="alertdialog" aria-labelledby="fmc4-dlg-h"','<div data-sheet="" role="{{ dlg.role }}" aria-labelledby="fmc4-dlg-h"',1,"A8 dialog role bound"),
 ('const dlgV = dlg ? { ...dlg, hasBody: !!dlg.body, login: !!dlg.login } : { actions: [] };',
  'const dlgV = dlg ? { ...dlg, hasBody: !!dlg.body, login: !!dlg.login, role: s.sheet === "discard" || s.sheet === "replace" ? "alertdialog" : "dialog" } : { actions: [], role: "dialog" };',1,"A8 alertdialog only for discard/replace"),
 ('{ ...act(s.intent.startsWith("edit") ? "Cancel edit" : "Discard", this.discard)','{ ...act(s.intent.startsWith("edit") ? "Discard changes" : "Discard", this.discard)',1,"A1 edit discard button = post.cancel_composer.discard_edit"),
 ('"Your post was submitted but it needs to be approved by a moderator before it will appear. Please be patient."',
  '"We\'ve received your new post but it needs to be approved by a moderator before it will appear. Please be patient."',1,"A1 approval body = review.approval.description"),
 ('linkLabel: s.link.edit ? "Edit link" : "Insert Hyperlink"','linkLabel: s.link.edit ? "Edit link" : "Insert link"',1,"A1 Insert link = composer.link_dialog_title"),
 ('aria-label="Link text (optional)" placeholder="Link text (optional)"','aria-label="Link text" placeholder="Link text"',1,"A1 Link text = composer.link_text_label"),
 ('aria-label="Search categories" placeholder="Search categories"','aria-label="Search categories" placeholder="Search…"',1,"A1 placeholder = select_kit.filter_placeholder (aria-label kept, proposed)"),
 ('mi("Build Poll",','mi("Build poll",',1,"A1 Build poll = poll.ui_builder.title (menu)"),
 ('poll: "Build Poll" }','poll: "Build poll" }',1,"A1 Build poll (sheet title)"),
 ('mi("Insert date",','mi("Insert date / time",',1,"A1 Insert date / time = discourse_local_dates.title (menu)"),
 ('date: "Insert date",','date: "Insert date / time",',1,"A1 Insert date / time (sheet title)"),
 ('[["regular", "Single choice"], ["multiple", "Multiple choice"]]','[["regular", "Single Choice"], ["multiple", "Multiple Choice"]]',1,"A1 poll types = poll.ui_builder.poll_type.*"),
 ('saving: ["fa-solid fa-circle-notch", "Saving draft…",','saving: ["fa-solid fa-circle-notch", "Saving",',1,"A1 saving status = composer.saving"),
 ('act("Overwrite Edits",','act("Overwrite Edit",',1,"A1 Overwrite Edit = composer.overwrite_edit (button)"),
 ('Overwrite Edits replaces the newer version with yours.','Overwrite Edit replaces the newer version with yours.',1,"A1 Overwrite Edit (banner body)"),
 ('    const liveNow_marker_never = 0;','',0,"noop"),
 ('      if (this.state.qsel && this.state.qsel.fake) this.measureFakeQuote();\n      if (!this.props.live) return;',
  '      if (this.state.qsel && this.state.qsel.fake) this.measureFakeQuote();\n      if (m.select && this._sc && this._el) { const f = this._el.querySelector(\'[data-fake="sel"]\'); if (f) { const sc = this._sc, sr = sc.getBoundingClientRect(), rc = f.getBoundingClientRect(), k = sc.offsetHeight ? sr.height / sc.offsetHeight : 1; if (rc.bottom > sr.bottom - 16) sc.scrollTop += (rc.bottom - sr.bottom + 32) / k; } }\n      if (!this.props.live) return;',1,"A7 scroll preset selection into view (16px rule)"),
])
# ---------- fmc4-lib.js ----------
edit("mockups/fmc4-lib.js",[
 ('if (!f.stage) e.stage = "This field is required"; if (!(f.piece || "").trim()) e.piece = "This field is required";',
  'if (!f.stage) e.stage = "Please fill out this field."; if (!(f.piece || "").trim()) e.piece = "Please fill out this field.";',1,"A1 form required = form_templates.errors.value_missing.default"),
 ('formErr: { stage: "This field is required", piece: "This field is required" }','formErr: { stage: "Please fill out this field.", piece: "Please fill out this field." }',1,"A1 C18-2 preset errors"),
 ('if (o.length < 2) return { err: "Poll must have at least 2 options." };','if (o.length < 1) return { err: "Enter at least 1 option." };',1,"A2 poll minimum 1 = poll.ui_builder.help.options_min_count"),
 ('return { err: "Poll options must be unique." };','return { err: "Poll must have different options." };',1,"A2 duplicate = default_poll_must_have_different_options"),
 ('err: "Poll options must be unique." } }]','err: "Poll must have different options." } }]',1,"A2 C08-8 preset"),
 ('  "C13-4": [{ ...W, cat: "lounge", banner: "forbidden", revoked: ["lounge"] }],',
  '  "C13-4": [{ ...W, cat: "lounge", banner: "forbidden", revoked: ["lounge"] }],\n  "C13-6": [{ intent: "reply", replyTo: "ravi", page: "topic", html: REPLY_NEW, banner: "noReply", draft: "saved" }],',1,"A6 C13-6 preset (reply permission revoked)"),
 ('P["C12-7"] = P.M5; P["C12-8"] = P.M5b; P["C13-1"] = P.M6; P["C14-1"] = P.M6b;',
  '// Aliases (r1, audit I-3): C12-7 = M5, C12-8 = M5b, C13-1 = M6, C14-1 = M6b. C12-6 is intentionally unused (I-2).\nP["C12-7"] = P.M5; P["C12-8"] = P.M5b; P["C13-1"] = P.M6; P["C14-1"] = P.M6b;',1,"A5 alias/retired-ID documentation"),
])
# ---------- 06.1 Prototype ----------
edit("mockups/06.1 Composer Prototype.dc.html",[
 ('R("TAB-9", "Portrait, uploads during rotation", { p: "C06-3", vp: "tabletP" }), R("TAB-10", "Landscape RTL, hardware keyboard", { p: "R1", vp: "tabletL", hw: true, rtl: true })',
  'R("TAB-9", "Portrait, destination sheet", { p: "C03", vp: "tabletP" }), R("TAB-10", "Landscape RTL, hardware keyboard", { p: "R1", vp: "tabletL", hw: true, rtl: true }), R("TAB-11", "Portrait, uploads during rotation", { p: "C06-3", vp: "tabletP" })',1,"A4 TAB-9 = destination sheet; new TAB-11 = uploads during rotation"),
 ('  "TAB-9": "Uploads keep running.','  "TAB-11": "Uploads keep running.',1,"A4 hint moved to TAB-11"),
 ('Close (×) while “Saving draft…” shows;','Close (×) while “Saving” shows;',1,"A1 hint follows composer.saving"),
 ('R("C12-7", "Minimized"), R("C12-8", "Drafts, resume")','R("C12-7", "Minimized (alias of M5)"), R("C12-8", "Drafts, resume (alias of M5b)")',1,"A5 alias labels"),
 ('R("C13-5", "Choose another category"), R("C19-3"','R("C13-5", "Choose another category"), R("C13-6", "Reply permission revoked"), R("C19-3"',1,"A6 C13-6 route"),
 ('if (["C13-4", "C13-5"].includes(id)) d.result = "forbidden";','if (["C13-4", "C13-5", "C13-6"].includes(id)) d.result = "forbidden";',1,"A6 C13-6 simulated result"),
])
# ---------- 06 Composer review ----------
edit("mockups/06 Composer.dc.html",[
 ('<span style="font:700 13px/1 var(--font-family);padding:7px 10px;border-radius:999px;background:#FFF1D6;color:#6B4A00;border:1px solid #E3C27A">Design awaiting your approval · not for implementation</span>',
  '<span style="font:700 13px/1 var(--font-family);padding:7px 10px;border-radius:999px;background:#FFF1D6;color:#6B4A00;border:1px solid #E3C27A">Design awaiting your approval · not for implementation</span><span style="font:700 13px/1 var(--font-family);padding:7px 10px;border-radius:999px;background:#fff;color:#45434C;border:1px solid #BDBAC6">Revision r1 · 2026-09-30 · audit corrections (handoff §12)</span>',1,"r1 revision badge"),
 ('B("TAB-9", "C03", "Portrait, destination sheet", { vp: "tabletP", dark: true, route: "C03", note: "Modal sheets are centred form sheets on tablet." }),',
  'B("TAB-9", "C03", "Portrait, destination sheet", { vp: "tabletP", dark: true, route: "TAB-9", note: "Modal sheets are centred form sheets on tablet." }),',1,"A4 TAB-9 routes to TAB-9"),
 ('B("TAB-10", "R1", "Landscape RTL, hardware keyboard", { vp: "tabletL", hw: true, rtl: true, dark: true, route: "TAB-10" }),\n  ] },',
  'B("TAB-10", "R1", "Landscape RTL, hardware keyboard", { vp: "tabletL", hw: true, rtl: true, dark: true, route: "TAB-10" }),\n    B("TAB-11", "C06-3", "Portrait, uploads during rotation", { vp: "tabletP", route: "TAB-11", note: "Static state. In the prototype, rotating to landscape or split keeps these uploads running." }),\n  ] },',1,"A4 new TAB-11 frame"),
 ('Draft status is always true: Saving draft…, Draft saved, Draft not saved, or Offline. Draft not saved.','Draft status is always true: Saving, Draft saved, Draft not saved, or Offline. Draft not saved.',1,"A1 drafts note follows composer.saving"),
 ('note: "Native 409 on stale edit (source). Overwrite Edits is core wording." }','note: "Native 409 on stale edit (source). Overwrite Edit is core wording (composer.overwrite_edit)." }',1,"A1 C15-3 note"),
 ('B("C13-5", "C13-5", "Choose another category"), B("C19-3"','B("C13-5", "C13-5", "Choose another category"), B("C13-6", "C13-6", "Reply permission revoked", { note: "Reply as linked topic is a native composer action; the banner copy is proposed." }), B("C19-3"',1,"A6 C13-6 frame"),
 ('below 330 CSS px the tool strip drops visible labels but keeps accessible names.','below 330 CSS px the tool strip and the draft status drop visible labels but keep accessible names (as built; the large-text status treatment LT is pending review).',1,"I-5 a11y section note matches behaviour"),
 ('Banners use role=alert. Dialogs use alertdialog with a labelled heading."]','Banners use role=alert. Dialogs use role=dialog with a labelled heading; only destructive confirmations (discard, replace text) use alertdialog."]',1,"A8 a11y spec"),
 ('Below 330 CSS px the strip shows icons with accessible names."]','Below 330 CSS px the strip and the draft status show icons with accessible names (as built; LT pending review)."]',1,"I-5 a11y table"),
 ('"Native Insert Hyperlink; contextual strip proposed"','"Native Insert link (composer.link_dialog_title); contextual strip proposed"',1,"A1 COV C07·a"),
 ('["C12", "Draft saving, close during save, failure, resume",','["C12", "Draft saving, close during save, failure, resume (C12-6 unused; C12-7 = M5, C12-8 = M5b)",',1,"A5 COV C12"),
 ('["C13", "Validation, rate limit, rejection, category revoked", "d", "M6 C13-2 C13-3 C13-4 C13-5",','["C13", "Validation, rate limit, rejection, category or reply permission revoked (C13-1 = M6)", "d", "M6 C13-2 C13-3 C13-4 C13-5 C13-6",',1,"A5/A6 COV C13"),
 ('["C14", "Offline", "d",','["C14", "Offline (C14-1 = M6b)", "d",',1,"A5 COV C14"),
 ('"TAB-1 TAB-3 TAB-4 TAB-5 TAB-6 TAB-7", "TAB-9",','"TAB-1 TAB-3 TAB-4 TAB-5 TAB-6 TAB-7 TAB-11", "TAB-11",',1,"A4 COV TAB route"),
])
# ---------- tokens / README ----------
edit("tokens/core-variables.css",[
 ('  --font-family: "Source Sans 3", "Source Sans Pro", system-ui, sans-serif;',
  '  /* "Source Sans 3" is the current name of Adobe\'s Source Sans Pro, served by Google Fonts for previews.\n     Discourse\'s base_font site setting is "Source Sans Pro"; production takes the font from that setting. */\n  --font-family: "Source Sans 3", "Source Sans Pro", system-ui, sans-serif;',1,"I-6 font-name clarification"),
])
edit("mockups/README.md",[
 ('Source Sans 3 for UI and body, Roboto Slab for titles.','Source Sans 3 for UI and body (preview name of Source Sans Pro; the Discourse base_font setting is Source Sans Pro), Roboto Slab for titles.',1,"I-6 font-name clarification"),
 ('See `06 Composer handoff.md` §4 for observed, fixture and proposed','See `06 Composer handoff.md` §6 for observed, core and proposed',1,"stale section reference (§4 → §6)"),
 ('`FmComposer4` (v4 composer frame + `fmc4-lib.js` fixtures;','`FmComposer4` (v4 composer frame + `fmc4-lib.js` fixtures; imports `FmHeader` and `FmBottomNav`;',1,"A9 dependency note"),
])
for l in log: print(" | ".join(map(str,l)))
