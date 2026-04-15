# Fomio Auth UI — Stitch Design Guide

*A complete system of Google Stitch prompts and workflow instructions for designing all Fomio authentication screens on the Discourse web theme.*

---

## What this guide covers

Every URL a user can hit during sign-in or sign-up on Fomio's Discourse backend needs to look and feel like Fomio — not Discourse. This guide gives you:

1. **How to use Google Stitch** — the workflow, modes, and tips specific to this project
2. **A global context prefix** — paste this before every prompt to keep the visual language consistent
3. **Ready-to-paste prompts** for all 17 auth screens, each with refinement follow-ups
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

**Purpose:** The user clicks the email link and lands here. Discourse shows an "Activate Account" button. One tap → account is live → Discourse redirects to `/` → mobile handoff overlay fires. This is **step 2 of 3** in the signup journey — not the finish line. The finish line is Screen 8 Variant B. Design this screen to feel like the penultimate moment: email confirmed, one tap away from being in.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the "Activate your account" screen for Fomio. The user has clicked their activation email link. There is a single primary action. This is step 2 of 3 in the signup flow.

Centered card (max-width 420px) on full-height cream page.

Card contents (top to bottom):
  - Three-step progress indicator, centered, below the card top edge:
      · Three dots in a horizontal row with connecting lines between them, 20px spacing
      · Dot 1: filled terracotta (#C44536), 10px diameter — "Account created"
      · Dot 2: filled terracotta (#C44536), 10px diameter — "Email confirmed" — this is the current step; add a soft terracotta glow halo (12px, 15% opacity) around it
      · Dot 3: empty circle, 10px diameter, #E3E3E6 border — "You're in"
      · Below each dot, a Raleway 10px muted label: "Account", "Email", "In"
  - Icon: 72px circle, terracotta fill (#C44536), white checkmark icon centered — clean, solid, not outlined
  - Small eyebrow: "STEP 2 OF 3" in Raleway 11px uppercase terracotta, letter-spacing 0.1em
  - Heading: "Activate your account" in Lora serif bold, 26px
  - Body: "Your email is confirmed. Tap below to complete your Fomio setup." Lora 16px relaxed.
  - Pill primary CTA: "Activate account" — 100% card width, 48px, terracotta fill, cream text, Raleway semibold, right-pointing chevron icon on the right side
  - Muted note below button: "You'll be taken to Fomio automatically." Raleway 12px muted, centered.

On mobile: full-screen card, centered vertically.

Animations: the checkmark icon entrance — circle scales from 0.6 to 1.0 with a spring ease (overshoot slightly to 1.05 then settle to 1.0, ~400ms) and the checkmark draws in with a path animation (stroke-dashoffset) over 300ms after the circle appears. Progress indicator dot 2's glow pulses gently (opacity 0.1–0.25, 2s ease-in-out infinite). The CTA button has a gentle shimmer animation (light sweep left to right, 1.5s interval) to draw the eye to the action.
```

**Refinement prompts:**

```
On the activate-account screen, make the connecting line between dot 1 and dot 2 on the progress indicator fully filled terracotta, and the connecting line between dot 2 and dot 3 empty (#E3E3E6), to clearly show how far along the user is.
```

```
On the activate-account screen, add an annotation note (small callout in the design file, not rendered on screen) marking that after the user taps "Activate account", Discourse redirects to "/" and Screen 8 Variant B (the congratulations handoff overlay) takes over as step 3.
```

---

### Screen 6A — `/password-reset` — Request reset

**Purpose:** The user has forgotten their password and needs to request a reset link. This is a task screen — one input, one action, done. Keep it focused and frictionless.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio "Reset your password" screen. This is a focused task screen — one input, one CTA.

Centered card (max-width 420px) on full-height cream page.

Card contents (top to bottom):
  - Fomio wordmark in Lora serif 20px, near-black, centered
  - Thin terracotta rule (2px × 28px, centered)
  - Heading: "Reset your password" — Lora bold 26px
  - Subtext: "We'll send a reset link to your email address." — Raleway 14px muted
  - Email input field with Raleway uppercase label "EMAIL ADDRESS" above (12px, letter-spacing 0.04em, muted), 40px input height, 12px border-radius, cream fill, 1px border #E3E3E6
  - Inline validation hint below input: when a valid email format is detected, show "We'll look for your account" in Raleway 12px green (#22C55E). Show this validated state in the design.
  - Pill primary CTA: "Send reset link" — terracotta fill, cream text, 48px height, 100% card width, Raleway semibold
  - Below button: left-pointing chevron + "Back to sign in" in Raleway 13px terracotta — consistent with the back-navigation pattern used across auth screens

On mobile: full-screen card, comfortable 16px padding.

Animations: card entrance fades and slides up 12px (320ms ease-out). Input focus: 2px terracotta border + soft cream-terracotta glow. CTA button: scale 0.97 on press (150ms).
```

**Refinement prompts:**

```
On the password reset request screen, make the email input's validated state also show a small green checkmark icon (18px) inside the right side of the input, matching the pattern used on the signup screen username field.
```

```
On the password reset request screen, add a subtle muted note below the CTA in Raleway 11px: "Check your spam folder if the email doesn't arrive." — positioned between the button and the back link, centered.
```

---

### Screen 6B — `/password-reset` (success) — Reset link sent

**Purpose:** The reset email has been sent. The user's task is complete — now they wait. This is a status screen, not a form. It should feel calm and reassuring, not busy. Structurally close to Screen 4 (Account Created) but the tone is more neutral — this could be anyone recovering access, not necessarily a new member.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio "Reset link sent" confirmation screen. The user has requested a password reset and the email is on its way. No form — this is a calm status screen.

Centered card (max-width 420px) on full-height cream page.

Card contents (top to bottom):
  - Icon: 64px line-art style envelope, near-black strokes (1.5px), with a small terracotta arrow leaving the top-right corner of the envelope flap — suggesting the email is already in transit. No cartoon fill. Editorial.
  - Heading: "Check your inbox." — Lora bold 26px — same short, declarative voice as Screen 4
  - Body: "We've sent a reset link to your email. It expires in 30 minutes." — Lora serif 16px, relaxed line-height, muted #6B6B72
  - Thin terracotta divider rule (1px, 32px wide, centered) as a visual pause before the actions
  - Secondary pill button: "Resend reset email" — outline style, 40px height, terracotta border and text, full card width
  - Below: left-pointing chevron + "Back to sign in" in Raleway 13px terracotta

On mobile: full-screen card, comfortable 16px padding.

Animations: card entrance fades and slides up 12px (320ms ease-out). The envelope icon has a gentle float animation (translate-y oscillating ±4px over 3s, ease-in-out, infinite) — the same motion used on the account-created envelope in Screen 4, keeping the two "waiting for email" screens visually consistent. The arrow on the envelope has a subtle upward drift (translate-y 0 → -3px, 2s ease-in-out, infinite, offset from the envelope's main float timing).
```

**Refinement prompts:**

```
On the password reset confirmation screen, add a small muted timestamp hint below the body copy — "Sent just now" in Raleway 11px muted — to give the screen a sense of immediacy without adding noise.
```

```
On the password reset confirmation screen, give the "Resend reset email" outline button a soft terracotta fill at 6% opacity as a background resting state, so it reads as slightly warmer than a pure white outline button without competing with a filled CTA.
```

---

### Screen 7A-1 — TOTP code entry — Default state

**Purpose:** The most common 2FA path. This is the resting/default state: boxes are empty, the CTA is muted until all 6 digits are filled. Run this prompt first, then run Screen 7A-2 for the error state as a separate generation.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio two-factor authentication screen — TOTP code entry, default state. This appears when a user has 2FA enabled and is signing in. The boxes are empty and the CTA is in its inactive/muted state.

The page is a full-height cream background (#F8F7F3) with a single centered card (max-width 400px, 18px border-radius, white fill, 1px border #E3E3E6, 32px internal padding). No navigation bar. No header. No footer. No watermarks. Nothing on the page except the card on the cream background.

Card contents, strictly in this order from top to bottom:
  1. Shield icon — 40px, centered. Line-art style: near-black strokes at 1.5px weight, terracotta (#C44536) fill on the shield notch/inner badge only. The shield body is not filled. No dot, badge, or notification indicator on or near the icon.
  2. Eyebrow label — "TWO-STEP VERIFICATION" in Raleway 11px, uppercase, terracotta (#C44536), letter-spacing 0.1em, centered. This is a label, not a heading.
  3. Heading — "Enter your code" in Lora serif bold, 24px, near-black (#1A1A1A), centered.
  4. Subtext — "Open your authenticator app and enter the 6-digit code." in Raleway 14px, muted (#6B6B72), centered.
  5. "CODE" label — Raleway 12px, uppercase, muted (#6B6B72), letter-spacing 0.08em, left-aligned above the box row.
  6. OTP box row — 6 individual boxes in a single horizontal row. Each box is a SQUARE with rounded corners: 8px border-radius. NOT circles. NOT pills. NOT ovals. Square boxes with slightly rounded corners only. Dimensions: 48px wide × 56px tall on desktop. Box fill: cream (#F8F7F3). Box border: 1px solid #E3E3E6. First box (leftmost) has 2px terracotta border (#C44536) to show it is focused/active. All boxes are empty — no digits inside. Space Mono font for any digits.
  7. CTA button — pill shape (9999px border-radius), full card width, 48px height. Label: "Verify" in Raleway semibold. Inactive/muted state: #E3E3E6 fill, #6B6B72 text. This button is inactive because no digits have been entered yet.
  8. Thin horizontal divider — 1px solid #E3E3E6, full card width.
  9. Two switch links — each on its own line, centered, Raleway 13px, terracotta (#C44536):
       · "Use a passkey instead"
       · "Use a backup code instead"

The card ends after the two switch links. Nothing below the card.

Do NOT add any of the following — these are explicitly excluded:
  - Navigation bars, header menus, or top-bar links ("Support", "Security", help icons)
  - Any dot, badge, or notification indicator on the shield icon
  - Footer text of any kind ("Secured by", protocol names, copyright, version numbers)
  - Watermarks or decorative text on the page background (Roman numerals, brand names, etc.)
  - Progress bars above or below the card
  - "Back to login", "Resend code", or any link not listed above
  - A "CODE" label in the heading position — "CODE" is only the small label above the box row

On mobile (viewport under 480px): the 6 OTP boxes must remain square with rounded corners and scale fluidly. Each box width = calc((100% - 40px) / 6). Height maintains 1:1.15 aspect ratio. The entire box row must fit within the card's inner width at all viewport sizes. Minimum tap target per box: 44px.

Animations: card fades in and slides up 12px on page load (320ms ease-out). No other animations on this static default state.
```

**Refinement prompts:**

```
On the 7A-1 TOTP default screen, show 3 of the 6 boxes in a partially filled state —
digits "1", "2", "3" in the first three boxes, with the fourth box showing the active
terracotta border (cursor position). Boxes 5 and 6 remain empty with the default
#E3E3E6 border. The Verify button remains muted. Do not change any other element.
```

```
On the 7A-1 TOTP default screen, produce an OTP variant as a second artboard:
change only the subtext to "We sent a 6-digit code to your email address." and
add a "Resend code  0:45" line in Raleway 13px terracotta below the two switch
links — "Resend code" as the link and "0:45" as muted countdown text beside it.
Keep all box shapes, card dimensions, heading, eyebrow, icon, and button identical
to the default state. Do not add a progress bar or any other new element.
```

---

### Screen 7A-2 — TOTP code entry — Error state

**Purpose:** The user submitted a wrong or expired code. Run this as a new Stitch generation after Screen 7A-1 is approved.

> **In Stitch:** Start a new generation. Reference Screen 7A-1 as the base.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio two-factor authentication screen — TOTP code entry, error state. The user has just submitted an incorrect code and the screen is showing the error.

The page layout is exactly the same as Screen 7A-1: full-height cream background (#F8F7F3), single centered card (max-width 400px, 18px border-radius, white fill, 1px border #E3E3E6, 32px internal padding). No navigation bar. No header. No footer. No watermarks.

Card contents, strictly in this order — identical to 7A-1 except where marked CHANGED:

  1. Shield icon — identical to 7A-1. 40px, line-art, terracotta notch only. No dot or badge.
  2. Eyebrow — identical to 7A-1. "TWO-STEP VERIFICATION", Raleway 11px uppercase terracotta.
  3. Heading — identical to 7A-1. "Enter your code", Lora bold 24px. Do NOT change this to "Verification Required" or any other text.
  4. Subtext — identical to 7A-1. "Open your authenticator app and enter the 6-digit code."
  5. "CODE" label — identical to 7A-1. Raleway 12px uppercase muted, left-aligned.
  6. OTP box row — CHANGED. Same SQUARE boxes with 8px border-radius as 7A-1 (not circles, not pills). All 6 boxes are filled with digits: "4", "8", "2", "1", "9", "3" in Space Mono. All 6 boxes now have a 2px red border (#EF4444) instead of the default border. No box has a terracotta border.
  7. Error message — CHANGED. New element inserted directly below the box row, before the button: "Incorrect code. Try again." in Raleway 13px, #EF4444, left-aligned with the box row.
  8. CTA button — identical label "Verify", identical pill shape — but back to muted state (#E3E3E6 fill, #6B6B72 text), same as the empty/inactive state in 7A-1.
  9. Thin divider — identical to 7A-1.
  10. Two switch links — identical to 7A-1. "Use a passkey instead" and "Use a backup code instead".

The card ends after the two switch links. Nothing below the card.

Do NOT add any of the following:
  - "Resend code" or "Resend" link — this is an error state for TOTP, not an OTP screen
  - "Back to login" or any back navigation link
  - A changed heading — the heading must remain "Enter your code"
  - Circular or pill-shaped boxes — boxes are square with 8px border-radius only
  - A "VERIFY ACCOUNT" button — the button label is "Verify", not "VERIFY ACCOUNT"
  - Navigation bars, footers, watermarks, or any element not listed above
```

---

### Screen 7B-1 — Passkeys — Default state

**Purpose:** The passkey path has no input field. The page exists to provide context and trigger the browser/OS native biometric dialog (Face ID, Touch ID, Windows Hello). This is the resting state — the CTA is fully active and waiting for the user to tap. Run this first, then run Screen 7B-2 for the loading state.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio passkey authentication screen — default/ready state. There is no input field. The page shows context and one button that will trigger the browser's native biometric or hardware key dialog.

Centered card (max-width 400px) on full-height cream page.

Card contents (top to bottom):
  - Icon: 56px, centered — a fingerprint outline in near-black line-art (1.5px strokes), with the center whorl detail filled in terracotta. Editorial, not a stock icon.
  - Eyebrow: "PASSKEY SIGN-IN" in Raleway 11px uppercase terracotta, letter-spacing 0.1em, centered
  - Heading: "Verify it's you" — Lora bold 24px
  - Subtext: "Use your fingerprint, face, or device PIN to continue." — Raleway 14px muted
  - Small muted note in Raleway 12px italic, centered: "Your browser will prompt you to authenticate."
  - Pill primary CTA: "Authenticate with passkey" — terracotta fill (#C44536), cream text, 48px height, 100% card width, Raleway semibold. Small fingerprint icon (16px, white) on the left side of the button label.
  - Thin divider rule (1px, #E3E3E6)
  - Two switch links below, Raleway 13px terracotta, each on its own line, centered:
      · "Use an authenticator code instead"
      · "Use a backup code instead"

On mobile: full-screen card.

Animations: card entrance fades + slides up 12px (320ms). The fingerprint icon pulses gently (opacity 0.85 ↔ 1.0, 2s ease-in-out infinite) to suggest the system is ready.
```

**Refinement prompt:**

```
On the 7B-1 passkey default screen, add a faint terracotta radial glow (12% opacity, 64px radius) behind the fingerprint icon, pulsing in sync with the icon's opacity animation — so the glow and the icon breathe together.
```

---

### Screen 7B-2 — Passkeys — Loading state

**Purpose:** The user has tapped "Authenticate with passkey" and the browser's native biometric dialog is about to appear (or is processing). The Fomio card remains visible behind the native OS dialog. Run this as a new Stitch generation after Screen 7B-1 is approved.

> **In Stitch:** Start a new generation. Reference Screen 7B-1 as the base.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio passkey authentication screen — loading state. This is the same screen as Screen 7B-1 after the user has tapped the CTA, while the browser's native biometric dialog is processing.

Keep every element — card dimensions, typography, icon, eyebrow, heading, subtext, divider, switch links — identical to Screen 7B-1. Change only the following:

  - CTA button: terracotta fill remains (#C44536). The button label changes from "Authenticate with passkey" to "Waiting for authentication…" in Raleway 13px. The fingerprint icon on the left is replaced by a white spinner (16px circle, 2px border, white with a transparent arc, spinning at 0.8s linear infinite).
  - The fingerprint icon above the heading continues its pulse animation unchanged — only the button changes.

Everything else is unchanged from Screen 7B-1.
```

---

### Screen 7C-1 — Backup codes — Default state

**Purpose:** The user is entering a single-use alphanumeric backup code to recover account access. The input is empty, the CTA is active. Run this first, then run Screen 7C-2 for the error state.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio backup code authentication screen — default state. The user is entering a single-use alphanumeric recovery code. Input is empty and ready.

Centered card (max-width 400px) on full-height cream page.

Card contents (top to bottom):
  - Icon: 48px — a small key in near-black line-art (1.5px strokes), horizontal orientation, with a small terracotta circle on the bow (top loop) of the key. Minimal, editorial.
  - Eyebrow: "BACKUP CODE" in Raleway 11px uppercase terracotta, letter-spacing 0.1em, centered
  - Heading: "Enter a backup code" — Lora bold 24px
  - Subtext: "Use one of the backup codes you saved when you set up two-factor authentication." — Raleway 14px muted
  - Single wide text input: full card width, 48px height, 16px border-radius, cream fill (#F8F7F3), 1px border #E3E3E6. Space Mono font inside. Placeholder text: "xxxx-xxxx-xxxx" in muted. Raleway uppercase 12px label above: "BACKUP CODE"
  - Amber warning pill directly below the input: background rgba(245,158,11,0.10), border 1px solid rgba(245,158,11,0.30), border-radius 999px, padding 6px 12px. Contains a ⚠ icon and Raleway 12px text: "Each backup code can only be used once."
  - Muted note below the warning pill: "Lost your backup codes? Contact support." in Raleway 11px muted, with "Contact support" as a terracotta link.
  - Pill primary CTA: "Verify backup code" — terracotta fill, cream text, 48px, 100% card width, Raleway semibold
  - Thin divider rule (1px, #E3E3E6)
  - Two switch links below, Raleway 13px terracotta, centered:
      · "Use an authenticator code instead"
      · "Use a passkey instead"

On mobile: full-screen card, comfortable 16px padding.

Animations: card entrance fades + slides up 12px (320ms). Input focus: 2px terracotta border + soft cream-terracotta glow. Warning pill fades in 200ms after the card settles.
```

**Refinement prompt:**

```
On the 7C-1 backup code default screen, show the input in a partially filled state — "a3f9-" with the cursor blinking after the dash — to illustrate the auto-formatting behaviour where a dash is inserted after every 4 characters as the user types.
```

---

### Screen 7C-2 — Backup codes — Error state

**Purpose:** The user submitted an invalid or already-used backup code. Run this as a new Stitch generation after Screen 7C-1 is approved.

> **In Stitch:** Start a new generation. Reference Screen 7C-1 as the base.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio backup code authentication screen — error state. This is the same screen as Screen 7C-1 after the user has submitted an invalid or already-used backup code.

Keep every element — card dimensions, typography, icon, eyebrow, heading, subtext, warning pill, support link, divider, switch links — identical to Screen 7C-1. Change only the following:

  - Input: 2px red border (#EF4444). Show a partially filled value ("a3f9-b2c1") in Space Mono inside the input to indicate a submitted entry.
  - Error message: directly below the input (above the warning pill), add "Invalid or already used backup code." in Raleway 13px, #EF4444, left-aligned.
  - Animation note (for implementation reference, not visible in static design): the input performs a horizontal shake keyframe (400ms) at the moment of error.

Everything else is unchanged from Screen 7C-1.
```

---

### Screen 8A — Mobile Handoff — Sign-in transit

**Purpose:** Fires from JavaScript on `/login` when the user taps that URL directly in mobile Safari (not via the app's auth session). It redirects them back to the Fomio app. This is a functional transit screen — no progress indicator, no celebration. Run this independently of Screen 8B.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio mobile browser handoff overlay — sign-in transit state. This is a full-viewport, fixed-position overlay on a pure cream canvas. No card, no border, no box-shadow. Content panel max-width 320px, centered both horizontally and vertically in the viewport.

Contents (top to bottom):
  - Eyebrow: "FOMIO" in Raleway 11px uppercase terracotta, letter-spacing 0.1em, centered
  - Thin terracotta rule (2px × 32px, centered)
  - Heading: "Continue in the app." — Lora serif bold, clamp(1.75rem, 5vw, 2.75rem), near-black, tight tracking (-0.02em), max-width 14ch, centered
  - Subtext: "Opening Fomio for sign in…" — Raleway 14px muted, centered
  - Spinner: 28px circle, 2px border, #E3E3E6 base with terracotta top arc (border-top-color #C44536), spinning continuously at 0.9s linear infinite
  - Fallback: "Not opening?" in Raleway 13px muted → "Tap here" in Raleway 13px terracotta semibold, on the same line

Background: #F8F7F3 cream fills the entire viewport. Nothing else.

Animations: eyebrow fades in 0–200ms, rule slides in 150–350ms, heading slides up 8px from below 200–500ms ease-out, subtext fades 350–550ms, spinner appears at 450ms+.
```

**Refinement prompt:**

```
On Screen 8A, give the heading a very subtle warm text shadow (1px 1px 0 rgba(255,255,255,0.5)) to lift it off the cream background without adding any colour to the canvas.
```

---

### Screen 8B — Mobile Handoff — Signup congratulations (step 3 of 3)

**Purpose:** Fires from JavaScript on `/` after the user completes account activation. This is step 3 of 3 in the signup journey — the arrival. It is not a loading screen; it is the congratulations moment. Design it as a distinct, warmer screen from Screen 8A. Run this independently.

**Prompt:**
```
[PASTE GLOBAL CONTEXT PREFIX]

Design the Fomio mobile browser handoff overlay — signup congratulations, step 3 of 3. This is a full-viewport, fixed-position overlay on a pure cream canvas. No card, no border, no box-shadow. Content panel max-width 320px, centered both horizontally and vertically in the viewport.

This is the arrival moment — the user has just completed account creation and email verification. It should feel calm, editorial, and quietly celebratory.

Contents (top to bottom):
  - Three-step progress indicator, centered:
      · Three dots in a horizontal row connected by lines
      · All three dots: filled terracotta (#C44536), 10px diameter
      · All connecting lines: filled terracotta
      · Dot 3 (rightmost): slightly larger at 13px, with a soft terracotta glow halo (16px radius, 20% opacity) — this is the step just completed
      · Below each dot, Raleway 10px muted labels: "Account", "Email", "In"
  - Icon: 56px circle, terracotta fill (#C44536), white checkmark centered — solid, resolved, no animated entrance needed
  - Eyebrow: "STEP 3 OF 3 — COMPLETE" in Raleway 11px uppercase terracotta, letter-spacing 0.1em, centered
  - Thin terracotta rule (2px × 32px, centered)
  - Heading: "You're in." — Lora serif bold, clamp(1.75rem, 5vw, 2.75rem), near-black, tight tracking (-0.02em). Short and decisive.
  - Subtext line 1: "Welcome to Fomio." — Lora serif regular 18px muted, centered
  - Subtext line 2: "Opening the app now…" — Raleway 14px muted, centered
  - Horizontal terracotta loading bar: 2px height, 80px wide, centered, fills left to right over 1.5s ease-in-out then loops
  - Fallback: "Not opening?" in Raleway 13px muted → "Tap here" in Raleway 13px terracotta semibold

Background: #F8F7F3 cream fills the entire viewport. Nothing else.

Animations: progress dots light up left to right (each: scale 0→1, 150ms, staggered 60ms apart). Then icon appears (spring scale 0.6→1.05→1.0, 400ms). Then eyebrow fades, rule slides in, heading slides up 8px, subtexts fade. Then loading bar begins. Total entrance ~900ms.
```

**Refinement prompts:**

```
On Screen 8B, add a very faint circular terracotta radial gradient behind the checkmark icon (80px radius, 8% opacity) as the only warm accent on the cream canvas. All other elements stay as designed.
```

```
On Screen 8B, make the terracotta loading bar slightly thicker at 3px and give it a soft rounded cap on both ends (border-radius: 9999px) so it reads as a deliberate brand element rather than a system progress bar.
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

| Screen | Route | Notes | Stitch prompt section |
|---|---|---|---|
| 1. Login | `/login` | Sign-in entry point | Part 3 → Screen 1 |
| 2. Authorize | `/user-api-key/new` | Trust-critical permission grant | Part 3 → Screen 2 |
| 3. Signup | `/signup?fomio=1` | New account form | Part 3 → Screen 3 |
| 4. Account created | `/u/account-created` | **Progress step 1+2** — check email | Part 3 → Screen 4 |
| 5. Activate account | `/u/activate-account/:token` | **Progress step 2** — confirm email | Part 3 → Screen 5 |
| 6A. Password reset — form | `/password-reset` | Request reset link | Part 3 → Screen 6A |
| 6B. Password reset — sent | `/password-reset` (success) | Confirmation screen | Part 3 → Screen 6B |
| 7A-1. TOTP — default | `/session/*` | Empty boxes, muted CTA | Part 3 → Screen 7A-1 |
| 7A-2. TOTP — error | `/session/*` | Red borders, error message | Part 3 → Screen 7A-2 |
| 7B-1. Passkeys — default | `/session/*` | Ready state, CTA active | Part 3 → Screen 7B-1 |
| 7B-2. Passkeys — loading | `/session/*` | Button with spinner, awaiting biometric | Part 3 → Screen 7B-2 |
| 7C-1. Backup codes — default | `/session/*` | Empty input, warning pill | Part 3 → Screen 7C-1 |
| 7C-2. Backup codes — error | `/session/*` | Red border, error message | Part 3 → Screen 7C-2 |
| 8A. Handoff — sign-in | `.fomio-mobile-handoff` on `/login` | Transit screen, no progress dots | Part 3 → Screen 8A |
| 8B. Handoff — welcome | `.fomio-mobile-handoff` on `/` | **Progress step 3 / congratulations** | Part 3 → Screen 8B |
| 9. Invites | `/invites` | Personal invitation acceptance | Part 3 → Screen 9 |

### The three-step progress system

Screens 4, 5, and 8B form a connected visual system across the signup journey:

| Step | Screen | Progress state |
|---|---|---|
| 1 (Account created) | Screen 4 `/u/account-created` | Dot 1 filled, dot 2 filled, dot 3 empty |
| 2 (Email confirmed) | Screen 5 `/u/activate-account/:token` | Dot 1 filled, dot 2 filled + glowing, dot 3 empty |
| 3 (You're in) | Screen 8B handoff overlay on `/` | All three dots filled, dot 3 slightly enlarged + glowing |

If you run Screen 4's progress indicator refinement prompt, you must also run Screen 5's and design Screen 8B accordingly — the three screens are a set.

---

*Last updated: 2026-04-12 — Fomio brand: terracotta primary #C44536, cream background #F8F7F3, Lora + Raleway type stack.*
