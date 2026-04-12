# Fomio Auth UI — Stitch Design Guide

*A complete system of Google Stitch prompts and workflow instructions for designing all Fomio authentication screens on the Discourse web theme.*

---

## What this guide covers

Every URL a user can hit during sign-in or sign-up on Fomio's Discourse backend needs to look and feel like Fomio — not Discourse. This guide gives you:

1. **How to use Google Stitch** — the workflow, modes, and tips specific to this project
2. **A global context prefix** — paste this before every prompt to keep the visual language consistent
3. **Ready-to-paste prompts** for all 9 auth screens, each with refinement follow-ups
4. **Implementation notes** — how the approved design translates into Discourse SCSS
5. **Iteration rules** — how to refine without breaking what's already working

---

## Part 1 — How to use Google Stitch

### Getting started

1. Go to **[stitch.withgoogle.com](https://stitch.withgoogle.com)**
2. Sign in with your Google account
3. Create a **new project** — name it `Fomio Auth UI`
4. Choose your generation mode:
   - **Experimental mode (Gemini 2.5 Pro)** → use this for *first passes* on each screen. Higher fidelity, more detail. (~50 generations/month)
   - **Standard mode (Gemini 2.5 Flash)** → use this for *refinement iterations*. Faster, still good. (~350 generations/month)

### The right workflow

**Don't start with individual screens.** Start with the visual language first — one global foundation prompt — then build each screen on top of it.

```
Step 1 → Global foundation prompt (sets palette, type, vibe) — Experimental mode
Step 2 → Screen-by-screen prompts, in order — Experimental mode for first pass
Step 3 → Refinement: one surgical change at a time — Standard mode
Step 4 → Export (Figma or HTML/CSS) when satisfied
```

### Stitch rules that matter for this project

- **One change per refinement prompt.** "Make the button terracotta, increase the heading size, and change the input border radius" will produce unpredictable results. Do each separately.
- **Name the element and its location.** "Change the button" fails. "Change the primary CTA button on the login screen" works.
- **If it doesn't land, rephrase — don't repeat.** Adding "please" or "really" doesn't help; adding "the pill-shaped primary CTA button in the login card center" does.
- **Always mention imagery when changing colors.** If you adjust the palette, add: *"Ensure all icons and illustrative elements match the new color scheme."*

---

## Part 2 — Global context prefix

Paste this at the start of every prompt. It locks in Fomio's brand system so screens stay consistent across sessions.

```
Fomio authentication screen — premium community reading and writing platform.
Responsive web page (Discourse-hosted; must work on mobile 320–767px, tablet 768–899px, desktop 900px+).

Brand palette (light mode):
  Background: #F8F7F3 (warm cream)
  Surface / card: #FFFFFF with border #E3E3E6
  Text: #1A1A1A (near-black)
  Muted text: #6B6B72
  Primary accent: #C44536 (terracotta)
  Primary dark (hover): #9E3326
  Success: #22C55E
  Danger: #EF4444

Typography:
  Headings: Lora serif — bold, tight tracking (-0.02em), editorial weight
  UI elements (inputs, buttons, labels, metadata): Raleway geometric sans-serif — medium/semibold, wide tracking (0.04em)
  Body copy: Lora at 16–18px, relaxed line-height 1.65

Shape language:
  Cards: 18px border-radius
  Buttons: pill shape (9999px), 48px height for primary CTAs, 40px for secondary
  Inputs: 12px border-radius, 40px height
  Dividers: 1px solid #E3E3E6

Premium editorial feel — calm, focused, unhurried. No gamification. No confetti. No gradient backgrounds. Subtle depth through light cream surface layering, not shadows.
```

---

## Part 3 — Auth screen prompts

### Screen 1 — Global foundation (start here)

**Purpose:** Establish the full visual language before designing any individual screen. Run this first in Experimental mode.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design a login screen for this platform. Centered auth card (max-width 440px) on a full-height cream page. The card sits on a white surface with an 18px border-radius and a 1px border (#E3E3E6), elevated slightly above the cream background.

Card contents (top to bottom):
  - Fomio wordmark in Lora serif at 22px, near-black, centered
  - Thin terracotta rule (2px wide, 32px wide, centered) beneath the wordmark as a brand accent
  - Heading: "Sign in" in Lora serif bold, 28px, near-black
  - Subtext: "Welcome back." in Raleway 14px, muted #6B6B72
  - Email or username input field with Raleway label above it, placeholder text "you@example.com", 40px height, 12px border-radius, cream fill, 1px border
  - Password input field, same style, with a show/hide eye toggle icon on the right, right-aligned
  - Pill-shaped primary CTA button labeled "Sign in", 100% card width, 48px height, terracotta #C44536 fill, cream #F8F7F3 text, Raleway semibold
  - Row below button: "Forgot password?" left-aligned in Raleway 13px, terracotta link; "Create account" right-aligned, terracotta link
  - Subtle horizontal divider and a "or continue with" label in Raleway 12px muted uppercase below (optional social auth row placeholder)

On mobile: card fills the full screen, no shadow border-radius, inputs stack full-width.
On desktop: card is centered in the viewport with generous vertical breathing room above and below.

Animations: inputs gain a soft terracotta glow (#C44536 at 20% opacity) on focus. The sign-in button has a gentle scale-down (0.97) on press. The entire card fades and slides up 12px on page load (duration 320ms, ease-out).

Ensure all icons (eye toggle, etc.) use terracotta as their active/focus color.
```

**Refinement prompts (run after the first pass):**

```
On the login screen, increase the spacing between the wordmark rule and the "Sign in" heading to give it more editorial breathing room. Keep the rule exactly as-is.
```

```
On the login screen, make the input focus state show a 2px terracotta border (#C44536) instead of the browser default, with a soft cream-terracotta inner glow. Update all input fields consistently.
```

```
On the login screen, add a very faint cream-to-white radial gradient behind the card on desktop, centered at the card, so the background has subtle depth without being distracting.
```

---

### Screen 2 — `/user-api-key/new` — Authorize Fomio

**Purpose:** The most trust-critical screen in the entire flow. The user sees this after logging in. They must tap "Authorize" to grant the mobile/CLI app access. It should feel like a deliberate, clear permission grant — not a dark pattern.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the "Authorize Fomio" permission screen for a User API Key delegation flow. This screen appears after the user logs in on the web, asking them to grant the Fomio app access to their account.

Centered permission card (max-width 480px) on a full-height cream page.

Card contents (top to bottom):
  - Fomio app icon placeholder: a 56px circle with terracotta background (#C44536) and a white "F" wordmark centered, above the card heading
  - Heading: "Allow Fomio to access your account" in Lora serif bold, 24px, near-black
  - Subtext: "Fomio is requesting the following permissions:" in Raleway 14px, muted
  - Permission list (3 rows, each with a small terracotta checkmark icon on the left):
      · "Read your profile and posts"
      · "Post and reply on your behalf"
      · "Manage your notifications"
    Each row: Raleway 14px, near-black, 40px row height, soft border between rows using #E3E3E6
  - Fomio branding line: "You're authorizing the official Fomio app." in Raleway 12px muted italic, centered, with a small lock icon in terracotta
  - Two pill buttons side by side: "Authorize" (terracotta fill, cream text, 48px) and "Cancel" (outline, #E3E3E6 border, near-black text, 48px). "Authorize" takes 60% width.

On mobile: buttons stack vertically, Authorize on top.

Animations: the permission rows appear in a staggered fade-in sequence (each 60ms apart, 240ms ease-out) after the card loads. The Authorize button scales down slightly (0.97) on press.

The overall tone should feel trustworthy and transparent — like a bank confirmation screen, not a pop-up ad.
```

**Refinement prompts:**

```
On the authorize screen, add a very subtle pulsing terracotta halo (low opacity, 2px ring) around the app icon at the top to draw the eye there first without being distracting.
```

```
On the authorize screen, make the permission rows have a soft cream background (#F8F7F3) with 8px border-radius each, slightly inset, so they read as distinct items rather than a flat list.
```

---

### Screen 3 — `/signup?fomio=1` — Create account

**Purpose:** New user registration. Opens via `openBrowserAsync` from the mobile app (so it's a real full browser, not the auth session). Should feel welcoming but fast.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio account creation / signup screen. Centered auth card (max-width 440px) on a full-height cream page.

Card contents (top to bottom):
  - Fomio wordmark in Lora serif at 22px, near-black, centered
  - Thin terracotta accent rule (2px × 32px) centered beneath wordmark
  - Heading: "Join Fomio" in Lora serif bold, 28px
  - Subtext: "Find your corner of the internet." in Raleway 14px, muted — this is the brand voice, keep it verbatim
  - Four input fields, each with a Raleway uppercase label (12px, wide tracking, muted) above:
      · Email address
      · Username (with inline validation state placeholder: green checkmark when valid)
      · Full name (optional — show "(optional)" label inline in muted text)
      · Password (with show/hide toggle, and a thin strength indicator bar below in terracotta at varying fill)
  - Small legal line below inputs: "By joining, you agree to our Terms and Privacy Policy." Raleway 11px, muted, links in terracotta
  - Pill primary CTA: "Create account" — 100% width, 48px, terracotta fill
  - Below button: "Already have an account? Sign in" in Raleway 13px, with "Sign in" as terracotta link

On mobile: card fills screen, all inputs full-width, comfortable 16px padding.

Animations: each input field entrance is staggered (40ms apart, translate-y 8px → 0, opacity 0→1) as the card loads. Focus state on all inputs: 2px terracotta border + soft glow. Password strength bar animates width as user types.
```

**Refinement prompts:**

```
On the signup screen, make the username input show a small green checkmark icon (20px) inside the right side of the input when the username is valid, and a small terracotta X when it's taken. Show the "valid" state in the design.
```

```
On the signup screen, add a small eyebrow label above the heading — "NEW ACCOUNT" in Raleway 11px uppercase terracotta, letter-spacing 0.1em — to give the card header more editorial structure.
```

---

### Screen 4 — `/u/account-created` — Check your email

**Purpose:** Post-signup confirmation state. Discourse renders this after the user submits the signup form. The user must check their email to activate. No form — just a clear, calm holding screen.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the "Check your email" confirmation screen for Fomio. This appears after a user creates an account. No form — this is a status/holding screen.

Centered card (max-width 420px) on full-height cream page.

Card contents:
  - Illustration / icon: a 72px circle with a soft cream-to-surface gradient fill, containing an envelope icon with a small terracotta accent (like a wax-seal dot on the envelope flap) — editorial, not cartoon
  - Heading: "One more step." in Lora serif bold, 26px — short, deliberate
  - Body copy (Lora serif, 16px, relaxed): "We've sent an activation link to your email address. Open it to complete your Fomio account."
  - Muted helper: "Can't find it? Check your spam folder." in Raleway 13px muted
  - Thin terracotta divider rule (1px, 32px wide, centered) as a visual pause
  - Secondary pill button: "Resend activation email" — outline style, 40px, terracotta border and text, full card width
  - Below: "Wrong email? Start over" in Raleway 13px, terracotta link

On mobile: same card, full screen width.

Animations: the envelope icon has a gentle float animation (translate-y oscillating ±4px over 3s, ease-in-out, infinite) to suggest something is in transit. The card entrance: fade + slide up 12px, 320ms. No other movement.
```

**Refinement prompts:**

```
On the account-created screen, change the envelope icon color to use a more editorial treatment: a line-art style envelope (1.5px strokes, near-black #1A1A1A) with only the wax-seal dot in terracotta. Keep the float animation.
```

```
On the account-created screen, add a small progress indicator below the heading — three dots: first filled terracotta (step 1: account created), second filled terracotta (step 2: check email), third empty/muted (step 3: you're in) — to orient the user in the flow.
```

---

### Screen 5 — `/u/activate-account/:token` — Activate account

**Purpose:** The user clicks the email link and lands here. Discourse shows an "Activate Account" button. One tap → account is live → redirect to `/` → mobile handoff fires. This is the finish line. Make it feel rewarding.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the "Activate your account" screen for Fomio. The user has clicked their activation email link and landed on this page. There is a single primary action. This is the final step before they're in.

Centered card (max-width 420px) on full-height cream page.

Card contents (top to bottom):
  - Icon: 72px circle, terracotta fill (#C44536), white checkmark icon centered — clean, solid, not outlined. This is the only "celebration" element.
  - Small eyebrow: "ALMOST THERE" in Raleway 11px uppercase terracotta, letter-spacing 0.1em
  - Heading: "Activate your account" in Lora serif bold, 26px
  - Body: "Your email is confirmed. Tap below to complete your Fomio setup." Lora 16px relaxed.
  - Pill primary CTA: "Activate account" — 100% card width, 48px, terracotta fill, cream text, Raleway semibold
  - Muted note below button: "You'll be taken to Fomio automatically." Raleway 12px muted, centered.

On mobile: full-screen card, centered vertically.

Animations: the checkmark icon entrance — circle scales from 0.6 to 1.0 with a spring ease (overshoot slightly to 1.05 then settle to 1.0, ~400ms) and the checkmark draws in with a path animation (stroke-dashoffset) over 300ms after the circle appears. The CTA button has a gentle shimmer animation (light sweep from left to right, 1.5s interval) to draw the eye to the action.
```

**Refinement prompts:**

```
On the activate-account screen, add a very subtle terracotta radial glow behind the icon (20% opacity, 80px radius) that pulses gently (opacity 0.1–0.2, 2s ease-in-out infinite) to reinforce that this is a live moment.
```

```
On the activate-account screen, change the "Activate account" button to also show a tiny right-pointing chevron arrow on the right side, to signal forward progression, keeping the pill shape and all other button styles.
```

---

### Screen 6 — `/password-reset` — Forgot password

**Purpose:** User requests a password reset email. Two states: (1) input form, (2) success "email sent" state.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio password reset screen. Show both states in the design:

STATE 1 — "Forgot your password?" form:
  Centered card (max-width 420px).
  - Fomio wordmark in Lora serif 20px, centered
  - Thin terracotta rule beneath (2px × 28px)
  - Heading: "Reset your password" — Lora bold 26px
  - Subtext: "We'll send a reset link to your email." — Raleway 14px muted
  - Email input field: Raleway label "Email address" above, 40px height, 12px border-radius
  - Pill primary CTA: "Send reset link" — terracotta fill, 48px, full width
  - Below: "Back to sign in" — Raleway 13px, terracotta link, left-aligned or centered

STATE 2 — "Email sent" confirmation (same card, different content):
  - Icon: soft envelope with a terracotta arrow-up leaving it (send motion), 64px
  - Heading: "Check your inbox." — Lora bold 26px
  - Body: "We've sent a reset link. It expires in 30 minutes." — Lora 16px
  - Secondary pill button: "Resend email" — outline, terracotta
  - Link: "Back to sign in"

Show State 1 as the primary design and State 2 inset smaller (as a second artboard or overlay) to the right or below.

On mobile: full screen, both states scroll naturally.

Animations (State 1→2 transition): the card content cross-fades (300ms) with a slight upward slide for State 2 content entering from below. No full-page reload feeling.
```

**Refinement prompts:**

```
On the password reset screen — State 1 — add inline validation under the email field: when a valid email format is detected, show a small Raleway 12px muted text "We'll look for your account" in green (#22C55E). Show this validation state in the design.
```

```
On the password reset screen, make the "Back to sign in" link include a small left-pointing chevron before the text, consistent with the activation screen's forward arrow pattern.
```

---

### Screen 7 — `/session/*` — Two-factor authentication (2FA)

**Purpose:** 2FA, OTP, passkeys, and backup codes all live under `/session/*`. This is a secondary but real path many users hit. Design for the most common case: 6-digit TOTP code entry.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio two-factor authentication screen. This appears when a user has 2FA enabled and is completing the login flow.

Centered card (max-width 400px) on full-height cream page.

Card contents:
  - Small shield icon with terracotta accent (40px), centered at top — editorial line-art style, near-black strokes, terracotta fill on the shield badge/notch only
  - Heading: "Two-step verification" — Lora bold 24px
  - Subtext: "Enter the 6-digit code from your authenticator app." — Raleway 14px muted
  - OTP input: 6 individual digit boxes in a row, each 48px × 56px, 8px border-radius, cream fill, 1px border (#E3E3E6). Active box has 2px terracotta border. Auto-advance cursor on digit entry. Monospace font (Space Mono) for the digits.
  - Pill primary CTA: "Verify" — terracotta fill, 100% width, 48px
  - Below CTA: two links in Raleway 13px muted — "Use a backup code" and "Use a passkey instead" — each on its own line, terracotta, underline on hover

On mobile: OTP boxes scale proportionally but maintain tap targets.

Animations: when all 6 digits are entered, the OTP row gets a brief terracotta border flash (box-shadow pulse, 200ms) before the Verify button activates. The Verify button remains visually muted (#E3E3E6 fill, muted text) until all 6 digits are present, then snaps to full terracotta with a 150ms transition.
```

**Refinement prompts:**

```
On the 2FA screen, add a small Raleway 12px muted label above the OTP boxes: "CODE" in uppercase, letter-spacing 0.08em — matching the eyebrow label style used on other auth screens.
```

```
On the 2FA screen, add an error state design: when the code is wrong, the 6 OTP boxes all get a red (#EF4444) border and shake horizontally (keyframe shake, 400ms), and a small error message "Incorrect code. Try again." appears below in Raleway 13px danger red.
```

---

### Screen 8 — Mobile Handoff Overlay (`.fomio-mobile-handoff`)

**Purpose:** This is a full-viewport overlay the web theme injects via JavaScript on `/login` (direct visit) and on home paths after sign-up. It tells the user to return to the Fomio app. Two variants: **login handoff** ("Continue in the app.") and **home handoff** ("You're all set.").

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio mobile browser handoff overlay. This is a full-viewport, fixed-position overlay that covers the entire Discourse page when the mobile browser should return control to the Fomio native app.

Full-screen layout (no card — the overlay IS the page):
  - Background: cream #F8F7F3 fills the entire viewport
  - Everything centered vertically and horizontally within the viewport
  - Content panel max-width 320px, centered

VARIANT A — "Continue in the app" (shown on /login when opened directly in mobile Safari):
  - Eyebrow: "FOMIO" in Raleway 11px uppercase terracotta, letter-spacing 0.1em, centered
  - Thin terracotta rule (2px × 32px, centered)
  - Heading: "Continue in the app." — Lora serif bold, clamp(1.75rem, 5vw, 2.75rem), near-black, tight tracking, max-width 14ch
  - Subtext: "Opening Fomio for sign in…" — Raleway 14px muted, centered
  - Spinner: 28px circle, 2px border, cream border with terracotta top segment (border-top-color #C44536), spinning continuously
  - Fallback below spinner: "Not opening?" in Raleway 13px muted, followed by a "Tap here" link in Raleway 13px terracotta semibold

VARIANT B — "You're all set" (shown on / after signup activation):
  - Same structure but heading: "You're all set." and subtext: "Opening Fomio…"

Show both variants side by side as two artboards.

No borders, no cards, no box-shadow — this is pure cream canvas.

Animations: the eyebrow fades in first (0–200ms), rule slides in (150–350ms), heading slides up from 8px below (200–500ms, ease-out), subtext fades (350–550ms), spinner appears (450ms+) and spins at 0.9s linear infinite.
```

**Refinement prompts:**

```
On the mobile handoff overlay, give the heading a very subtle warm text shadow (1px 1px 0 rgba(255,255,255,0.5)) to lift it off the cream background. Keep the cream background pure — no color change.
```

```
On the mobile handoff overlay, replace the spinner with a more editorial animation: a horizontal terracotta loading bar (2px height, cream background) that fills from left to right over 1.5s with an ease-in-out curve, then loops. The bar should be 80px wide, centered, beneath the subtext.
```

---

### Screen 9 — `/invites` — Accept invitation

**Purpose:** A user received an invitation link. They land here to create their account. Similar to signup but with a warmer welcome tone — they were personally invited.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio invitation acceptance screen. A user has received a personal invite link and is creating their account through it.

Centered card (max-width 440px) on full-height cream page.

Card contents:
  - Small eyebrow: "YOU'RE INVITED" in Raleway 11px uppercase terracotta, letter-spacing 0.1em, centered
  - Thin terracotta rule (2px × 32px, centered)
  - Heading: "Join the conversation." — Lora bold 28px
  - Subtext: "Someone thought you'd feel at home here." — Raleway 14px muted, italic
  - Thin divider rule (1px, #E3E3E6, full card width)
  - Three input fields with Raleway uppercase labels:
      · Username
      · Password (with show/hide toggle)
      · Password confirm
  - Pill primary CTA: "Accept invitation" — terracotta fill, 48px, 100% width
  - Muted note: "By accepting, you agree to our Terms and Privacy Policy." Raleway 11px muted

On mobile: full-screen, comfortable 16px padding.

Animations: same staggered entrance as signup screen. The eyebrow label has a very faint terracotta underline that draws from left to right on page load (width 0% → 100%, 600ms, ease-out) as a subtle brand animation.
```

---

## Part 4 — Implementation in the Discourse theme

Stitch outputs HTML/CSS or Figma components. Here's how to translate that into the Discourse web theme.

### What Discourse controls vs. what you control

| Element | Who controls it |
|---|---|
| Form fields (input names, validation, submission) | Discourse — Ruby + Ember |
| Page routing and redirects | Discourse — Ruby routes |
| Card layout, colors, typography, spacing | **You — SCSS in `apps/web/`** |
| Animations (fade-in, focus states, transitions) | **You — SCSS in `apps/web/`** |
| Full-page overlays (handoff) | **You — JS + SCSS in `apps/web/`** |

You are **not** writing new Ember components or Ruby code. You are writing SCSS that overrides Discourse's default auth page styles.

### Where to put the SCSS

```
apps/web/common/common.scss   ← shared (applies to all widths)
apps/web/desktop/desktop.scss ← desktop + tablet overrides (768px+)
apps/web/mobile/mobile.scss   ← mobile-only overrides (0–767px)
```

Discourse applies `mobile.scss` automatically on mobile breakpoints via its own stylesheet split — you don't add media queries for that split. Within `desktop.scss` you can use `@media` for tablet vs. desktop if needed.

### Token usage rule

Never hardcode hex values in SCSS. Use the `--fomio-*` variables already defined in `common.scss` Section 1:

```scss
// ✅ Correct
background: var(--fomio-primary);
color: var(--fomio-text);

// ❌ Wrong
background: #C44536;
color: #1A1A1A;
```

### Scoping auth styles correctly

Discourse adds body classes for auth pages. Use these to scope your styles:

```scss
// Login page
body.login-page { }

// Signup page
body.signup-page { }

// Account created
body.account-created { }

// Activate account — token path
body.activate-account { }

// Password reset
body.password-reset-page { }

// User API Key auth
body.user-api-key-auth { }
```

Verify the exact body class Discourse applies by inspecting the page in your dev instance before writing SCSS.

### Exporting from Stitch

1. In Stitch, click **Export → Copy CSS** (or **Export to Figma** for handoff)
2. Take the layout and spacing values — these are what you actually need
3. Replace all hardcoded colors in the export with `var(--fomio-*)` variables
4. Replace all font-family values with `var(--fomio-font-serif)` or `var(--fomio-font-ui)`
5. Paste into the correct `apps/web/` stylesheet under the appropriate body class scope

### Animation implementation pattern

Stitch may generate keyframe animations with hardcoded timing. Here's how to adapt them cleanly:

```scss
// In common.scss — define the keyframes once
@keyframes fomio-auth-enter {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fomio-auth-input-appear {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

// Apply in the auth page scope
body.login-page {
  .login-form {
    animation: fomio-auth-enter 320ms ease-out both;
  }

  .input-group:nth-child(1) { animation: fomio-auth-input-appear 240ms 40ms ease-out both; }
  .input-group:nth-child(2) { animation: fomio-auth-input-appear 240ms 80ms ease-out both; }
  .input-group:nth-child(3) { animation: fomio-auth-input-appear 240ms 120ms ease-out both; }
}
```

The `fomio-mobile-handoff` keyframe (`fomio-mobile-handoff-spin`) already exists in `common.scss` Section 16 — extend that pattern for new auth animations.

### Responsive implementation

For the auth card behavior:

```scss
// common.scss — shared card shell
.fomio-auth-card {
  background: var(--fomio-card);
  border: 1px solid var(--fomio-border);
  border-radius: var(--fomio-radius-card);  // 18px
  padding: var(--fomio-space-2xl);          // 32px
  width: 100%;
  max-width: 440px;
  margin: 0 auto;
}

// mobile.scss — full-bleed on mobile
.fomio-auth-card {
  border-radius: 0;
  border-left: none;
  border-right: none;
  max-width: 100%;
  min-height: 100dvh;
}

// desktop.scss — centered with breathing room
.fomio-auth-page {
  min-height: 100dvh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--fomio-space-4xl) var(--fomio-space-xl);
  background: var(--fomio-bg);
}
```

---

## Part 5 — Iteration rules

Once you have a first-pass design you're happy with in Stitch, use these rules to refine without breaking the system.

**Rule 1 — One element, one prompt.**
Each refinement should target exactly one component: the button, the input, the heading, the icon.

**Rule 2 — Name the screen and the element together.**
"On the login screen, change the primary CTA button…" — not just "change the button."

**Rule 3 — Check cross-screen consistency after every 3 refinements.**
Put all screens side by side in Stitch and ask: "Do these all look like they belong to the same product?" If not, run a consistency prompt:

```
Review all auth screens together. Ensure:
1. The Lora serif heading is the same size (28px login, 26px others) and weight (bold) on every card
2. The Raleway muted subtext is the same size (14px) and color (#6B6B72) everywhere
3. The terracotta accent rule (2px × 32px) appears on every screen with a Fomio wordmark
4. All primary CTA buttons are pill-shaped, 48px height, terracotta fill, cream text, Raleway semibold
```

**Rule 4 — Export to Figma for spacing verification.**
Stitch → Figma export lets you inspect exact spacing values (padding, margins, gaps). This is what you need for SCSS implementation.

**Rule 5 — Tablet view is a Discourse responsibility with optional SCSS tweaks.**
Discourse handles layout reflow at 768px. Only add `desktop.scss` tablet overrides if the card layout breaks or feels cramped. Start with no tablet-specific overrides and add only what's necessary.

---

## Appendix — Quick reference: all 9 prompts at a glance

| Screen | Route | Stitch prompt section |
|---|---|---|
| 1. Login | `/login` | Part 3 → Screen 1 |
| 2. Authorize | `/user-api-key/new` | Part 3 → Screen 2 |
| 3. Signup | `/signup?fomio=1` | Part 3 → Screen 3 |
| 4. Account created | `/u/account-created` | Part 3 → Screen 4 |
| 5. Activate account | `/u/activate-account/:token` | Part 3 → Screen 5 |
| 6. Password reset | `/password-reset` | Part 3 → Screen 6 |
| 7. Two-factor auth | `/session/*` | Part 3 → Screen 7 |
| 8. Mobile handoff | `.fomio-mobile-handoff` | Part 3 → Screen 8 |
| 9. Invites | `/invites` | Part 3 → Screen 9 |

---

*Last updated: 2026-04-12 — Fomio brand: terracotta primary #C44536, cream background #F8F7F3, Lora + Raleway type stack.*
