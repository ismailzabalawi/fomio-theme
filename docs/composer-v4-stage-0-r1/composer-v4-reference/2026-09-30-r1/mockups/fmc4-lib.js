(function () {
const esc = (s) => String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const inl = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>").replace(/\*(.+?)\*/g, "<em>$1</em>").replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>').replace(/(^|\s)(https?:\/\/[^\s<]+)/g, '$1<a href="$2">$2</a>');
const P_ = "<p><br></p>";
const URL1 = "https://example.org/slow-mornings";
const PB = [
  { user: "maya", name: "Maya Chen", initial: "M", color: "#A0527A", when: "1d", text: "What small habit made your mornings easier? Mine is leaving the curtains open so the light wakes me before the alarm." },
  { user: "ravi", name: "Ravi Patel", initial: "R", color: "#6A7F2E", when: "20h", text: "I keep the kettle filled the night before. Two minutes saved, but it feels like the morning has already started." },
  { user: "jun", name: "Jun", initial: "J", color: "#56708A", when: "3h", mine: true, text: "The charger lives in the hallway now. I read on paper until breakfast." },
];
const USERS = [
  { u: "maya", n: "Maya Chen", c: "#A0527A" }, { u: "marek", n: "Marek Nowak", c: "#8A5A2E" }, { u: "mariana", n: "Mariana Costa", c: "#2F7D6D" },
  { u: "ravi", n: "Ravi Patel", c: "#6A7F2E" }, { u: "editors", n: "Editors", c: "#56708A", group: true },
];
const CATS = [
  { id: "open", parent: "General", name: "Open Discussions", color: "#56708A", groups: null, desc: "Anything that does not fit elsewhere." },
  { id: "q", parent: "General", name: "Questions", color: "#B07A1E", groups: null, desc: "Ask one clear question. Say what you have tried.", guide: true },
  { id: "craft", parent: "Craft", name: "Writing workshop", color: "#6A7F2E", groups: null, desc: "Share drafts and ask for feedback." },
  { id: "form", parent: "Craft", name: "Feedback requests", color: "#8A5A9E", groups: null, desc: "Share a piece and say what feedback you want.", form: true },
  { id: "lounge", parent: null, name: "Members lounge for regulars and long-time readers", color: "#A0527A", groups: ["Regulars"], desc: "For members of the Regulars group." },
  { id: "desk", parent: null, name: "Editors’ desk", color: "#56708A", groups: ["Editors", "Moderators"], desc: "Planning notes for the editing team." },
];
const catById = (id) => CATS.find((c) => c.id === id) || CATS[0];
const catV = (c) => ({ path: c.parent ? c.parent + " › " + c.name : c.name, color: c.color, visIcon: c.groups ? "fa-solid fa-lock" : "fa-solid fa-earth-americas", visText: c.groups ? c.groups.join(" and ") + " only" : "Public", desc: c.desc, guide: !!c.guide, form: !!c.form });
const TPLS = { prose: { name: "Short prose", piece: "Your piece", ph: "Paste or write the piece here." }, poem: { name: "Poem", piece: "Your poem", ph: "Keep line breaks as you want them read." } };
const FORM = { stage: "What stage is it at?", stages: ["First draft", "Revised", "Nearly finished"], fb: "What feedback do you want?", fbs: ["Clarity", "Pacing", "Word choice"], note: "Anything readers should know?" };
const composeForm = (f) => { const t = TPLS[f.tpl] || TPLS.prose; const out = ["### " + FORM.stage + "\n\n" + (f.stage || ""), "### " + t.piece + "\n\n" + (f.piece || "")]; if (f.fb && f.fb.length) out.push("### " + FORM.fb + "\n\n" + f.fb.map((x) => "- " + x).join("\n")); if ((f.note || "").trim()) out.push("### " + FORM.note + "\n\n" + f.note.trim()); return out.join("\n\n"); };
const formErrors = (f) => { const e = {}; if (!f.stage) e.stage = "Please fill out this field."; if (!(f.piece || "").trim()) e.piece = "Please fill out this field."; return e; };
const LANGS = { "": "Automatic", javascript: "JavaScript", python: "Python", shell: "Shell", text: "Plain text" };
const TZS = ["Europe/London", "America/New_York", "Asia/Tokyo"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
function atomInfo(md) {
  if (/^\[poll/.test(md)) { const n = (md.match(/^\* /gm) || []).length; return ["fa-solid fa-square-poll-vertical", "Poll · " + n + " options, " + (/type=multiple/.test(md) ? "multiple" : "single") + " choice", "poll"]; }
  if (/^\[details/.test(md)) { const m = md.match(/^\[details="([^"]*)"/); return ["fa-solid fa-caret-right", "Hidden details · " + (m ? m[1] : ""), "details"]; }
  if (/^\[date/.test(md)) { const d = (md.match(/date=(\d{4})-(\d\d)-(\d\d)/) || []), t = (md.match(/time=(\d\d:\d\d)/) || [])[1] || "", tz = (md.match(/timezone="([^"]+)"/) || [])[1] || ""; return ["fa-regular fa-calendar", "Date · " + (d[3] ? +d[3] + " " + MONTHS[+d[2] - 1] + " " + d[1] : "") + (t ? ", " + t : "") + (tz ? " · " + tz : ""), "date"]; }
  if (/^\[spoiler/.test(md)) return ["fa-solid fa-circle-half-stroke", "Blurred spoiler", "spoiler"];
  if (/^\|/.test(md)) { const rows = md.split("\n").filter((l) => /^\|/.test(l)); const cols = rows[0].split("|").length - 2; return ["fa-solid fa-table", "Table · " + cols + " columns, " + Math.max(0, rows.length - 2) + " rows", "table"]; }
  const lang = (md.match(/^```(\w*)/) || [])[1] || ""; const lines = Math.max(1, md.split("\n").length - 2);
  return ["fa-solid fa-code", "Code" + (lang ? " · " + (LANGS[lang] || lang) : "") + " · " + lines + " line" + (lines === 1 ? "" : "s"), "code"];
}
const SELSTYLE = "outline:2px solid var(--tertiary);outline-offset:3px;";
const atomFig = (md, sel) => { const [ic, lb, ty] = atomInfo(md); return `<figure contenteditable="false" data-kind="atom" data-type="${ty}" data-md="${esc(md)}" style="${sel ? SELSTYLE : ""}margin:0 0 14px;display:flex;align-items:center;gap:10px;padding:12px 14px;border-radius:8px;border:1px solid var(--content-border-color);background:var(--primary-very-low);font:600 15px/1.3 var(--font-family);cursor:pointer"><i class="${ic}" style="color:var(--primary-medium)"></i><span style="overflow-wrap:anywhere">${esc(lb)}</span></figure>`; };
const imgFig = (name, md, sel) => `<figure contenteditable="false" data-kind="img" data-name="${esc(name)}" data-md="${esc(md)}" style="${sel ? SELSTYLE : ""}margin:4px 0 16px;display:flex;flex-direction:column;gap:6px;border-radius:8px;cursor:pointer"><span style="display:flex;align-items:center;justify-content:center;height:170px;border-radius:8px;background:var(--primary-low);color:var(--primary-medium)"><i class="fa-regular fa-image" style="font-size:28px"></i></span><figcaption style="font:14px/1.3 var(--font-family);color:var(--primary-medium)">${esc(name)}</figcaption></figure>`;
const upFig = (id, name, pct) => `<figure contenteditable="false" data-kind="up" data-up="${id}" data-name="${esc(name)}" data-pct="${pct}" style="margin:4px 0 16px"><span style="display:flex;align-items:center;gap:12px;padding:10px 6px 10px 14px;border-radius:8px;background:var(--primary-very-low);border:1px solid var(--content-border-color)"><i class="fa-regular fa-image" style="color:var(--primary-medium)"></i><span style="flex:1;min-width:0;display:flex;flex-direction:column;gap:6px"><span style="font:600 15px/1.2 var(--font-family);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(name)}</span><span role="progressbar" aria-label="${esc(name)}" aria-valuenow="${pct}" aria-valuemin="0" aria-valuemax="100" style="display:block;height:4px;border-radius:2px;background:var(--primary-low);overflow:hidden"><span data-bar="" style="display:block;height:100%;width:${pct}%;background:var(--tertiary)"></span></span><span data-pct-t="" style="font:14px/1 var(--font-family);color:var(--primary-medium)">Uploading… ${pct}%</span></span><button type="button" data-act="cancel" style="height:44px;padding:0 12px;border:0;border-radius:8px;background:none;color:var(--primary-high);font:600 15px/1 var(--font-family);cursor:pointer">Cancel</button></span></figure>`;
const failFig = (id, name) => `<figure contenteditable="false" data-kind="fail" data-up="${id}" data-name="${esc(name)}" style="margin:4px 0 16px"><span role="alert" style="display:flex;flex-wrap:wrap;align-items:center;gap:8px 12px;padding:10px 8px 10px 14px;border-radius:8px;background:var(--danger-low);border:1px solid var(--danger)"><i class="fa-solid fa-circle-exclamation" style="color:var(--danger)"></i><span style="flex:1;min-width:140px;display:flex;flex-direction:column;gap:3px"><strong style="font:700 15px/1.2 var(--font-family)">Upload failed</strong><span style="font:14px/1.3 var(--font-family);color:var(--primary-high);overflow-wrap:anywhere">${esc(name)} was not added.</span></span><span style="display:flex;gap:4px"><button type="button" data-act="retry" style="height:44px;padding:0 14px;border:0;border-radius:8px;background:var(--tertiary);color:var(--on-tertiary);font:700 15px/1 var(--font-family);cursor:pointer">Retry</button><button type="button" data-act="remove" style="height:44px;padding:0 12px;border:0;border-radius:8px;background:none;color:var(--primary-high);font:600 15px/1 var(--font-family);cursor:pointer">Remove</button></span></span></figure>`;
const quoteMd = (p, idx, text) => `[quote="${p.user}, post:${idx + 1}, topic:4127"]\n${text}\n[/quote]`;
const quoteFig = (p, text, md, sel) => `<figure contenteditable="false" data-kind="quote" data-md="${esc(md)}" style="${sel ? SELSTYLE : ""}margin:0 0 14px;padding:10px 14px 12px;border-radius:8px;background:var(--primary-very-low);border:1px solid var(--content-border-color);cursor:pointer"><span style="display:flex;align-items:center;gap:8px;margin-bottom:6px;font:700 14px/1.2 var(--font-family);color:var(--primary-high)"><span style="width:22px;height:22px;border-radius:50%;background:${p.color};color:#fff;font:700 11px/22px var(--font-family);text-align:center">${p.initial}</span>${esc(p.name)}:</span><span style="display:block;font:16px/1.55 var(--font-family);color:var(--primary-high);unicode-bidi:plaintext">${esc(text)}</span></figure>`;
const host = (u) => { try { return new URL(u).hostname; } catch (e) { return u; } };
const obCard = (url, sel) => `<figure contenteditable="false" data-kind="ob" data-md="${esc(url)}" style="${sel ? SELSTYLE : ""}margin:0 0 14px;padding:12px 14px;border-radius:8px;border:1px solid var(--content-border-color);display:flex;flex-direction:column;gap:4px;cursor:pointer"><span style="display:flex;align-items:center;gap:6px;font:13px/1.2 var(--font-family);color:var(--primary-medium)"><i class="fa-solid fa-globe"></i>${esc(host(url))}</span><span style="font:700 16px/1.3 var(--font-family);color:var(--tertiary)">Slow mornings: notes from a year of quieter starts</span><span style="font:14px/1.45 var(--font-family);color:var(--primary-high)">What changed when I stopped reaching for my phone first thing.</span></figure>`;
const obLoad = (id, url) => `<figure contenteditable="false" data-kind="obload" data-ob="${id}" data-md="${esc(url)}" aria-label="Loading preview" style="margin:0 0 14px;display:flex;align-items:center;gap:10px;padding:12px 14px;border-radius:8px;border:1px dashed var(--primary-low-mid);font:15px/1.3 var(--font-family);color:var(--primary-medium)"><i class="fa-solid fa-circle-notch" style="animation:fmc4spin 800ms linear infinite"></i><span style="min-width:0;overflow-wrap:anywhere">${esc(url)}</span></figure>`;
const obFail = (url) => `<figure contenteditable="false" data-kind="obfail" data-md="${esc(url)}" style="margin:0 0 14px;display:flex;flex-direction:column;gap:6px"><a href="${esc(url)}" style="overflow-wrap:anywhere">${esc(url)}</a><span style="display:flex;flex-wrap:wrap;align-items:center;gap:6px 10px;font:14px/1.35 var(--font-family);color:var(--primary-high)"><i class="fa-solid fa-circle-info" style="color:var(--primary-medium)"></i><span style="flex:1;min-width:160px">Preview unavailable. The link will be posted as written.</span><button type="button" data-act="obretry" style="height:44px;padding:0 12px;border:1px solid var(--input-border-color);border-radius:8px;background:var(--secondary);color:var(--primary);font:600 14px/1 var(--font-family);cursor:pointer">Try again</button></span></figure>`;
const plainLink = (url) => `<p><a href="${esc(url)}">${esc(url)}</a></p>`;
function mdToHtml(md) {
  const L = (md || "").replace(/\r/g, "").split("\n"); const out = []; let para = [], i = 0, m;
  const flush = () => { if (para.length) { out.push("<p>" + para.map(inl).join("<br>") + "</p>"); para = []; } };
  while (i < L.length) {
    const l = L[i];
    if (!l.trim()) { flush(); i++; continue; }
    if ((m = l.match(/^!\[([^|\]]*)(?:\|[^\]]*)?\]\((upload:\/\/[^)]+)\)\s*$/))) { flush(); out.push(imgFig((m[1] || "photo") + ".jpg", l.trim())); i++; continue; }
    if (/^https?:\/\/\S+$/.test(l.trim()) && !para.length) { flush(); out.push(obCard(l.trim())); i++; continue; }
    if ((m = l.match(/^\[quote="(\w+), post:(\d+)/))) { flush(); const buf = []; i++; while (i < L.length && !/^\[\/quote\]/.test(L[i])) { buf.push(L[i]); i++; } i++; const p = PB.find((x) => x.user === m[1]) || PB[1]; const text = buf.join("\n"); out.push(quoteFig(p, text, `[quote="${m[1]}, post:${m[2]}, topic:4127"]\n${text}\n[/quote]`)); continue; }
    if (/^\[(poll|details|spoiler)/.test(l)) { flush(); const tag = l.match(/^\[(\w+)/)[1]; const buf = [l]; i++; if (!l.includes("[/" + tag + "]")) { while (i < L.length && !L[i - 1].includes("[/" + tag + "]")) { buf.push(L[i]); i++; } } out.push(atomFig(buf.join("\n"))); continue; }
    if (/^\[date=/.test(l)) { flush(); out.push(atomFig(l.trim())); i++; continue; }
    if (/^\|/.test(l)) { flush(); const buf = []; while (i < L.length && /^\|/.test(L[i])) { buf.push(L[i]); i++; } out.push(atomFig(buf.join("\n"))); continue; }
    if (/^```/.test(l)) { flush(); const buf = [l]; i++; while (i < L.length && !/^```/.test(L[i])) { buf.push(L[i]); i++; } if (i < L.length) { buf.push(L[i]); i++; } out.push(atomFig(buf.join("\n"))); continue; }
    if ((m = l.match(/^(#{2,3}) (.*)/))) { flush(); const n = m[1].length; out.push(`<h${n}>${inl(m[2])}</h${n}>`); i++; continue; }
    if (/^> ?/.test(l)) { flush(); const buf = []; while (i < L.length && /^> ?/.test(L[i])) { buf.push(L[i].replace(/^> ?/, "")); i++; } out.push("<blockquote><p>" + buf.map(inl).join("<br>") + "</p></blockquote>"); continue; }
    if (/^[-*] /.test(l)) { flush(); const buf = []; while (i < L.length && /^[-*] /.test(L[i])) { buf.push("<li>" + inl(L[i].slice(2)) + "</li>"); i++; } out.push("<ul>" + buf.join("") + "</ul>"); continue; }
    if (/^\d+\. /.test(l)) { flush(); const buf = []; while (i < L.length && /^\d+\. /.test(L[i])) { buf.push("<li>" + inl(L[i].replace(/^\d+\. /, "")) + "</li>"); i++; } out.push("<ol>" + buf.join("") + "</ol>"); continue; }
    para.push(l); i++;
  }
  flush(); return out.join("");
}
function htmlToMd(html) {
  const d = document.createElement("div"); d.innerHTML = html || "";
  const inline = (n) => { let s = ""; n.childNodes.forEach((c) => { if (c.nodeType === 3) { s += c.textContent; return; } if (c.nodeType !== 1 || (c.dataset && (c.dataset.fake === "caret"))) return; const t = c.tagName, v = inline(c); if (t === "STRONG" || t === "B") s += v.trim() ? `**${v}**` : v; else if (t === "EM" || t === "I") s += v.trim() ? `*${v}*` : v; else if (t === "A") { const h = c.getAttribute("href") || ""; s += v === h ? h : `[${v}](${h})`; } else if (t === "BR") s += "\n"; else s += v; }); return s; };
  const blocks = [];
  const walk = (n) => n.childNodes.forEach((c) => {
    if (c.nodeType === 3) { if (c.textContent.trim()) blocks.push(c.textContent.trim()); return; }
    if (c.nodeType !== 1) return; const t = c.tagName;
    if (t === "FIGURE") { if (c.dataset.md) blocks.push(c.dataset.md); return; }
    if (t === "H1" || t === "H2") blocks.push("## " + inline(c).trim());
    else if (t === "H3" || t === "H4") blocks.push("### " + inline(c).trim());
    else if (t === "UL") blocks.push([...c.children].map((li) => "- " + inline(li).trim()).join("\n"));
    else if (t === "OL") blocks.push([...c.children].map((li, j) => (j + 1) + ". " + inline(li).trim()).join("\n"));
    else if (t === "BLOCKQUOTE") { const inner = c.children.length ? [...c.children].map((x) => inline(x).trim()).join("\n") : inline(c).trim(); blocks.push(inner.split("\n").map((x) => "> " + x).join("\n")); }
    else if (c.querySelector("figure,ul,ol,blockquote,p,h2,h3")) walk(c);
    else { const v = inline(c).replace(/\u00a0/g, " ").trim(); if (v) blocks.push(v); }
  });
  walk(d); return blocks.join("\n\n");
}
const publish = (html) => mdToHtml(htmlToMd(html)).replace(/contenteditable="false"/g, "").replace(/cursor:pointer/g, "");
function parseAtom(md) {
  const ty = atomInfo(md)[2];
  if (ty === "table") { const rows = md.split("\n").filter((l) => /^\|/.test(l) && !/^\|\s*-/.test(l)).map((l) => l.split("|").slice(1, -1).map((x) => x.trim())); return { type: ty, rows }; }
  if (ty === "details") { const m = md.match(/^\[details="([^"]*)"\]\n?([\s\S]*?)\n?\[\/details\]/); return { type: ty, summary: m ? m[1] : "", content: m ? m[2] : "" }; }
  if (ty === "date") return { type: ty, date: (md.match(/date=([\d-]+)/) || [])[1] || "", time: ((md.match(/time=(\d\d:\d\d)/) || [])[1]) || "", tz: (md.match(/timezone="([^"]+)"/) || [])[1] || TZS[0] };
  if (ty === "spoiler") return { type: ty, text: (md.match(/^\[spoiler\]([\s\S]*)\[\/spoiler\]/) || [])[1] || "" };
  if (ty === "poll") return { type: ty, ptype: /type=multiple/.test(md) ? "multiple" : "regular", opts: (md.match(/^\* (.*)$/gm) || []).map((x) => x.slice(2)).join("\n") };
  const lines = md.split("\n"); return { type: "code", lang: (lines[0].match(/^```(\w*)/) || [])[1] || "", code: lines.slice(1, -1).join("\n") };
}
function newAtom(type) {
  return { table: { type, rows: [["", ""], ["", ""]] }, details: { type, summary: "", content: "" }, date: { type, date: "2026-10-03", time: "08:00", tz: TZS[0] }, spoiler: { type, text: "" }, code: { type, lang: "", code: "" }, poll: { type, ptype: "regular", opts: "" } }[type];
}
function buildAtom(a) {
  if (a.type === "table") { const rows = a.rows.map((r) => r.map((c) => c.replace(/\|/g, "/"))); if (!rows[0].some((c) => c.trim())) return { err: "Add at least one column heading." }; return { md: ["| " + rows[0].join(" | ") + " |", "| " + rows[0].map(() => "---").join(" | ") + " |", ...rows.slice(1).map((r) => "| " + r.join(" | ") + " |")].join("\n") }; }
  if (a.type === "details") { if (!a.summary.trim()) return { err: "Add a summary." }; return { md: `[details="${a.summary.trim().replace(/"/g, "'")}"]\n${a.content}\n[/details]` }; }
  if (a.type === "date") { if (!a.date) return { err: "Choose a date." }; return { md: `[date=${a.date}${a.time ? " time=" + a.time + ":00" : ""} timezone="${a.tz}"]` }; }
  if (a.type === "spoiler") { if (!a.text.trim()) return { err: "Add the text to blur." }; return { md: `[spoiler]${a.text}[/spoiler]` }; }
  if (a.type === "code") { if (!a.code.trim()) return { err: "Add the code or text to preformat." }; return { md: "```" + a.lang + "\n" + a.code + "\n```" }; }
  const o = a.opts.split("\n").map((x) => x.trim()).filter(Boolean);
  if (o.length < 1) return { err: "Enter at least 1 option." };
  if (new Set(o.map((x) => x.toLowerCase())).size !== o.length) return { err: "Poll must have different options." };
  return { md: `[poll type=${a.ptype} results=always chartType=bar]\n${o.map((x) => "* " + x).join("\n")}\n[/poll]` };
}
const TITLE = "What small habit made your mornings easier?";
const LONG = "A slightly embarrassing question about mornings: does anyone else plan the whole day in bed, then forget all of it by the time the coffee is ready, and how do you stop that happening?";
const CARET = '<span data-fake="caret" style="display:inline-block;width:2px;height:1.15em;margin:0 1px;vertical-align:-0.2em;background:var(--tertiary)"></span>';
const W1 = "<p>I stopped checking my phone before the kettle boils. It sounds small, but the first ten minutes are quieter now.</p>";
const W2 = (mid) => `<p>What changed things for you? I would like to try ${mid} this month.</p>`;
const WRITE = W1 + W2("one more thing every morning");
const WRITE_C = W1 + W2("one more thing every morning").replace("</p>", CARET + "</p>");
const SEL = W1 + W2('<span data-fake="sel" style="background:var(--highlight);border-radius:2px;box-shadow:0 0 0 2px var(--highlight)">one more thing every morning</span>');
const MIX = "I stopped checking my phone before the kettle boils. It sounds **small**, but the first ten minutes are quieter now.\n\n![kettle-window|690x460](upload://k3tlw1nd0w.jpeg)\n\nWhat I tried:\n\n- Charger in the hallway\n- Window open for five minutes\n- One page of a book\n\n> Slow is smooth.\n\nMore notes on [slow mornings](" + URL1 + ").";
const LINKED = W1 + '<p>I got the idea from a post on <a href="' + URL1 + '">slow mornings</a>' + CARET + ".</p>";
const LINKSEL = W1 + '<p>I got the idea from a post on <span data-fake="sel" style="background:var(--highlight);box-shadow:0 0 0 2px var(--highlight)">slow mornings</span>.</p>';
const REPLY_NEW = "<p>Same here. I put the charger in the hallway, so the phone stays there until after breakfast.</p>";
const EDITED = "<p>The charger lives in the hallway now. I read on paper until breakfast, usually one chapter.</p>";
const OTHER = W1 + "<p>What changed things for you? I am trying a slower start every weekday this month.</p>";
const AR_T = "ما العادة الصغيرة التي جعلت صباحك أسهل؟";
const AR_B = "<p>توقفت عن تفقد هاتفي قبل أن يغلي الماء. تبدو خطوة صغيرة، لكن الدقائق العشر الأولى أصبحت أهدأ." + CARET + "</p>";
const MX_T = "Mornings, and the word صباح";
const MX_B = "<p>My grandmother wrote this on the fridge, and it still works for me:</p><p>الصباح رباح، فابدأ بهدوء.</p><p>It roughly means the morning brings gain, so start calmly. I read it before the kettle" + CARET + ".</p>";
const Q1 = quoteFig(PB[1], "Two minutes saved, but it feels like the morning has already started.", quoteMd(PB[1], 1, "Two minutes saved, but it feels like the morning has already started."));
const Q0 = quoteFig(PB[0], "leaving the curtains open so the light wakes me before the alarm", quoteMd(PB[0], 0, "leaving the curtains open so the light wakes me before the alarm"));
const FORM_FULL = { tpl: "prose", stage: "First draft", piece: "The lighthouse keeper counted the ships he no longer saw. There were fewer every winter, and he began to name the empty nights instead.", fb: ["Pacing"], note: "About 900 words; this is the opening." };
const FORM_EMPTY = { tpl: "prose", stage: "", piece: "", fb: [], note: "" };
const BASE = { view: "composer", page: "feed", intent: "new", replyTo: null, mode: "rich", title: "", md: "", html: "", cat: "open", kb: false, field: null, panel: null, sheet: null, ctx: "caret", fmt: {}, draft: null, errors: {}, banner: null, submitting: false, similar: "collapsed", reasonOpen: false, reason: "", preview: false, full: false, minimized: false, drafts: [], pendingNotice: false, published: false, replyOpen: false, destQ: "", link: { url: "", text: "" }, alt: "", signedOut: false, closed: false, fakeTitleCaret: false, notice: null, announce: "", edited: false, mention: null, qsel: null, atomEd: null, photoSel: [], drag: false, closing: false, session: false, revoked: [], form: FORM_EMPTY, formErr: {}, formPreview: false, editedTitle: null, pendingSwitch: null, upN: 0 };
const W = { title: TITLE, html: WRITE, draft: "saved" };
const SELIMG = (name) => imgFig(name, `![${name.replace(/\.\w+$/, "")}|690x460](upload://u1x7Qe.jpeg)`, true);
const POLLMD = "[poll type=regular results=always chartType=bar]\n* Charger in the hallway\n* Window open\n* One page of a book\n[/poll]";
const P = {
  M1: [{ kb: true, field: "title", fakeTitleCaret: true }, { focus: "title" }],
  M2: [{ ...W, html: WRITE_C, kb: true, field: "body" }, { caret: 1 }],
  M3: [{ ...W, html: SEL, kb: true, field: "body", panel: "format", ctx: "text" }, { select: 1 }],
  M4: [{ ...W, html: WRITE + upFig("u1", "IMG_2041.jpeg", 62) + P_ }, { up: 1 }],
  M4b: [{ ...W, html: WRITE + failFig("u1", "IMG_2041.jpeg") + P_ }],
  M5: [{ ...W, view: "page", minimized: true }],
  M5b: [{ ...W, view: "page", drafts: [{ title: TITLE, meta: "Create topic · just now" }] }],
  M6: [{ title: "Tea", html: "", draft: "saved", errors: { title: "Title must be at least 5 characters", body: "Post must be at least 2 characters" } }],
  M6b: [{ ...W, banner: "offline", draft: "offline" }, { sim: { net: "offline" } }],
  C01: [{}], C02: [{ cat: "q" }], C03: [{ sheet: "dest" }],
  C04: [{ ...W, html: mdToHtml(MIX) }],
  C05: [{ ...W, mode: "md", md: MIX }], C05b: [{ ...W, sheet: "more" }], C05p: [{ ...W, mode: "md", md: MIX, preview: true }],
  "C06-1": [{ ...W, sheet: "photo" }],
  "C06-2": [{ ...W, sheet: "photo", photoSel: ["IMG_2041.jpeg", "IMG_2040.jpeg", "IMG_2038.jpeg"] }],
  "C06-3": [{ ...W, html: WRITE + upFig("u1", "IMG_2041.jpeg", 84) + upFig("u2", "IMG_2040.jpeg", 46) + upFig("u3", "IMG_2038.jpeg", 12) + P_ }, { up: 1 }],
  "C06-4": [{ ...W, html: WRITE + imgFig("IMG_2041.jpeg", "![IMG_2041|690x460](upload://u1x7Qe.jpeg)") + failFig("u2", "IMG_2040.jpeg") + imgFig("IMG_2038.jpeg", "![IMG_2038|690x460](upload://u3x7Qe.jpeg)") + P_ }],
  "C06-5": [{ ...W, html: WRITE + SELIMG("IMG_2041.jpeg") + P_, ctx: "image" }, { blk: 'figure[data-kind="img"]' }],
  "C06-6": [{ ...W, html: WRITE + SELIMG("IMG_2041.jpeg") + P_, ctx: "image", panel: "alt", alt: "Kettle on the windowsill at sunrise" }, { blk: 'figure[data-kind="img"]' }],
  "C06-7": [{ ...W, drag: true }],
  "C06-8": [{ ...W, notice: "type" }],
  "C06-9": [{ ...W, html: WRITE + upFig("u1", "IMG_2041.jpeg", 38) + P_, errors: { body: "Wait for the photos to finish uploading." } }],
  "C07-1": [{ ...W, html: W1 + obLoad("ob1", URL1) + P_ }, { ob: 1 }],
  "C07-2": [{ ...W, html: W1 + obCard(URL1) + P_ }],
  "C07-3": [{ ...W, html: W1 + plainLink("https://example.org/archive/2019/morning-notes.pdf") + P_ }],
  "C07-4": [{ ...W, html: W1 + obFail(URL1) + P_ }],
  "C07-5": [{ ...W, html: LINKED, kb: true, field: "body", ctx: "link" }, { caret: 1 }],
  "C07-6": [{ ...W, html: LINKSEL, kb: true, field: "body", panel: "link", link: { url: "https://", text: "slow mornings" } }, { select: 1 }],
  "C07-7": [{ ...W, html: LINKED, kb: true, field: "body", panel: "link", ctx: "link", link: { url: URL1, text: "slow mornings", edit: true } }],
  "C08-1": [{ ...W, sheet: "more" }],
  "C08-2": [{ ...W, sheet: "more" }, { sim: { poll: false, dates: false } }],
  "C08-3": [{ ...W, sheet: "atom", atomEd: { type: "table", rows: [["Habit", "Minutes saved"], ["Charger in the hallway", "10"], ["Kettle filled the night before", "2"]] } }],
  "C08-4": [{ ...W, sheet: "atom", atomEd: { type: "details", summary: "What I tried first", content: "Three alarms, five minutes apart. It did not help." } }],
  "C08-5": [{ ...W, sheet: "atom", atomEd: { type: "date", date: "2026-10-03", time: "08:00", tz: "Europe/London" } }],
  "C08-6": [{ ...W, sheet: "atom", atomEd: { type: "spoiler", text: "The habit that stuck was the smallest one." } }],
  "C08-7": [{ ...W, sheet: "atom", atomEd: { type: "code", lang: "shell", code: "alarm --at 07:00 --label kettle" } }],
  "C08-8": [{ ...W, sheet: "atom", atomEd: { type: "poll", ptype: "regular", opts: "Charger in the hallway\ncharger in the hallway", err: "Poll must have different options." } }],
  "C08-9": [{ ...W, html: W1 + atomFig(POLLMD, true) + P_, ctx: "atom" }, { blk: 'figure[data-kind="atom"]' }],
  "C08-10": [{ ...W, html: W1 + "<p>Thanks for the idea, @ma" + CARET + "</p>", kb: true, field: "body", mention: { q: "ma", status: "results", sel: 0 } }, { caret: 1 }],
  "C08-11": [{ ...W, html: W1 + "<p>Thanks for the idea, @ma" + CARET + "</p>", kb: true, field: "body", mention: { q: "ma", status: "loading", sel: 0 } }, { caret: 1 }],
  "C08-12": [{ ...W, html: W1 + "<p>Thanks for the idea, @zq" + CARET + "</p>", kb: true, field: "body", mention: { q: "zq", status: "none", sel: 0 } }, { caret: 1 }],
  C09: [{ title: TITLE, similar: "open" }],
  "C10-1": [{ intent: "reply", page: "topic", kb: true, field: "body" }],
  "C10-2": [{ intent: "reply", replyTo: "ravi", page: "topic", replyOpen: true, html: REPLY_NEW, draft: "saved" }],
  "C10-3": [{ view: "page", page: "topic", qsel: { post: 1, fake: true, text: "Two minutes saved, but it feels like the morning has already started." } }],
  "C10-4": [{ intent: "reply", replyTo: "ravi", page: "topic", html: Q1 + "<p>Same here. Filling it the night before is the whole trick" + CARET + "</p>", kb: true, field: "body", draft: "saved" }, { caret: 1 }],
  "C10-5": [{ intent: "reply", replyTo: "ravi", page: "topic", html: Q1 + "<p>Same here. Filling it the night before is the whole trick.</p>" + Q0 + P_, draft: "saved" }],
  "C10-6": [{ intent: "reply", replyTo: "ravi", view: "page", page: "topic", published: true, html: Q1 + "<p>Same here. Filling it the night before is the whole trick.</p>" }],
  C11: [{ intent: "editFirst", page: "topic", title: TITLE, html: "<p>" + PB[0].text + "</p>", reasonOpen: true }],
  C11b: [{ intent: "edit", page: "topic", html: "<p>" + PB[2].text + "</p>" }],
  "C12-1": [{ ...W, draft: "saving" }, { hold: 1 }],
  "C12-2": [{ ...W }],
  "C12-3": [{ ...W, draft: "saving", closing: true }, { hold: 1 }],
  "C12-4": [{ ...W, draft: "failed", banner: "saveFailed" }, { sim: { draft: "fail" } }],
  "C12-5": [{ ...W, draft: "offline", banner: "closeOffline" }, { sim: { net: "offline" } }],
  "C12-9": [{ ...W, sheet: "discard" }],
  "C13-2": [{ ...W, banner: "rate" }],
  "C13-3": [{ ...W, banner: "rejected" }],
  "C13-4": [{ ...W, cat: "lounge", banner: "forbidden", revoked: ["lounge"] }],
  "C13-6": [{ intent: "reply", replyTo: "ravi", page: "topic", html: REPLY_NEW, banner: "noReply", draft: "saved" }],
  "C13-5": [{ ...W, cat: "lounge", banner: "forbidden", revoked: ["lounge"], sheet: "dest" }],
  "C14-2": [{ ...W, draft: "offline" }, { sim: { net: "offline" } }],
  "C15-1": [{ ...W, html: WRITE, draft: "draftConflict", banner: "draftConflict" }, { sim: { draft: "conflict" } }],
  "C15-2": [{ ...W, draft: "draftConflict", banner: "draftConflict", sheet: "replace" }, { sim: { draft: "conflict" } }],
  "C15-3": [{ intent: "edit", page: "topic", html: EDITED, banner: "conflict", draft: "conflict" }, { conflict: 1 }],
  "C16-1": [{ ...W, submitting: true }, { busy: 1 }],
  "C16-2": [{ ...W, view: "page", page: "newtopic", published: true }],
  "C16-3": [{ intent: "reply", view: "page", page: "topic", published: true, html: REPLY_NEW }],
  "C16-4": [{ intent: "edit", view: "page", page: "topic", published: true, edited: true, html: EDITED }],
  "C16-5": [{ ...W, banner: "error" }],
  C17: [{ ...W, view: "page", page: "feed", sheet: "pending" }],
  "C18-1": [{ cat: "form", title: "The lighthouse keeper’s last winter" }],
  "C18-2": [{ cat: "form", title: "The lighthouse keeper’s last winter", draft: "saved", form: { ...FORM_EMPTY, fb: ["Pacing"] }, formErr: { stage: "Please fill out this field.", piece: "Please fill out this field." } }],
  "C18-3": [{ cat: "form", title: "The lighthouse keeper’s last winter", draft: "saved", form: FORM_FULL, formPreview: true }],
  "C18-4": [{ cat: "form", title: "The lighthouse keeper’s last winter", draft: "saved", form: FORM_FULL, sheet: "formSwitch", pendingSwitch: "craft" }],
  "C18-5": [{ cat: "form", title: "The lighthouse keeper’s last winter", view: "page", page: "newtopic", published: true, form: FORM_FULL }],
  "C19-1": [{ view: "page", page: "topic", signedOut: true, sheet: "login" }],
  "C19-2": [{ view: "page", page: "topic", closed: true }],
  "C19-3": [{ intent: "reply", replyTo: "ravi", page: "topic", html: REPLY_NEW, banner: "closedNow", closed: true, draft: "saved" }],
  "C19-4": [{ ...W, banner: "session", session: true, draft: "failed" }],
  "C19-5": [{ ...W, banner: "session", session: true, draft: "failed", sheet: "login" }],
  R1: [{ title: AR_T, html: AR_B, kb: true, field: "body", draft: "saved" }, { caret: 1 }],
  MX: [{ title: MX_T, html: MX_B, kb: true, field: "body", draft: "saved" }, { caret: 1 }],
  L1: [{ title: LONG, cat: "lounge", html: WRITE, draft: "saved" }],
  L2: [{ title: LONG, cat: "desk", html: WRITE, draft: "saved" }],
};
// Aliases (r1, audit I-3): C12-7 = M5, C12-8 = M5b, C13-1 = M6, C14-1 = M6b. C12-6 is intentionally unused (I-2).
P["C12-7"] = P.M5; P["C12-8"] = P.M5b; P["C13-1"] = P.M6; P["C14-1"] = P.M6b;
function preset(id) { const [st, meta] = P[id] || P.C01; return { st: { ...BASE, ...st }, meta: meta || {} }; }
const SIMILAR = [{ t: "Morning routines that actually stuck", m: "General › Open Discussions · 24 replies" }, { t: "Phones out of the bedroom: one year later", m: "General › Open Discussions · 41 replies" }, { t: "How do you start the day without the news?", m: "General › Questions · 9 replies" }];
const FEED = [{ title: "Recommend a notebook that survives a bag", meta: "Craft › Writing workshop · 2h" }, { title: "What are you reading this week?", meta: "General › Open Discussions · 5h" }, { title: TITLE, meta: "General › Open Discussions · 1d" }];
const GEO = {
  phone: { w: 390, h: 844, st: 47, safe: 34, keyH: 42, r: 48, kind: "phone", dev: "phone" },
  narrow: { w: 360, h: 740, st: 36, safe: 20, keyH: 38, r: 28, kind: "phone", dev: "phone" },
  splitNarrow: { w: 375, h: 834, st: 24, safe: 20, keyH: 52, r: 18, kind: "phone", dev: "tablet" },
  split600: { w: 600, h: 834, st: 24, safe: 20, keyH: 52, r: 18, kind: "tablet", dev: "tablet" },
  tabletP: { w: 834, h: 1194, st: 24, safe: 20, keyH: 58, r: 18, kind: "tablet", dev: "tablet" },
  tabletL: { w: 1194, h: 834, st: 24, safe: 20, keyH: 52, r: 18, kind: "tablet", dev: "tablet" },
  desktop: { w: 1280, h: 800, st: 0, safe: 0, keyH: 0, r: 12, kind: "desktop", dev: "desktop" },
};
window.FMC4 = { esc, P_, URL1, PB, USERS, CATS, catById, catV, TPLS, FORM, composeForm, formErrors, LANGS, TZS, atomFig, imgFig, upFig, failFig, quoteFig, quoteMd, obCard, obLoad, obFail, plainLink, mdToHtml, htmlToMd, publish, parseAtom, newAtom, buildAtom, TITLE, OTHER, BASE, preset, SIMILAR, FEED, GEO };
})();
