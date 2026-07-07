# MetAfter — Design & Flow Specification

> Source of truth: Figma file "MetAfter" (Sign Up Flow board, main screen board, full
> flow map). This document transcribes every screen, state, transition and animation
> so engineering work can proceed without access to the Figma file.
> Last updated: 2026-07-07.

MetAfter is a **Bluetooth-proximity professional networking app**. Discovery and
connection happen device-to-device over BLE. All personal data (profiles seen,
crossed paths, connections, messages) lives **on the device**. The cloud is an
identity + transport layer only (OTP auth, E2E-encrypted relay, push wake-ups) —
see `ARCHITECTURE.md` in `metafter-backend` for the system design.

---

## 1. Design language

| Token | Value | Usage |
| --- | --- | --- |
| Brand red | `#E5342B` (primary), lighter `#F03D33` for buttons on dark | Buttons, wordmark, accents |
| Red gradient | red → deep red → near-black, vertical | Splash, onboarding, profile pages, Home lower glow |
| Green gradient | dark top → vivid green bottom | Home/Meet page **discoverable** state |
| Dark surface | near-black `#0A0A0A` | Home shell background |
| Light surface | white | Discover, Messages, Requests, Settings, Sign-up |
| Date band | very light red/pink tint | Discover date header row |
| Type | Geometric sans (existing app theme) | Titles bold, body regular |
| Buttons | Full-width, rounded (~12px), red bg + white text on light; white/light bg + dark text variant on dark ("Let's Go!") | Primary CTAs |
| Cards/fields | 1px light-grey outline, ~10px radius | Sign-up fields, request rows |

Existing Lottie assets: `assets/animation/ripple.json` (outward ripple — radar
pulse), `assets/animation/inward-ripple.json` (session ending / not discoverable),
`assets/animation/pull-up.json` (bottom pull-up affordance).

---

## 2. Navigation model

The app shell after login is a **horizontally swipeable 3-page carousel**:

```
[ Discover ]  ⇄  [ Home / Meet ]  ⇄  [ Messages ]
```

- Top bar: back-chevron left, red **MetAfter** wordmark centered, chevron right.
- Below it, a **page-title strip** that behaves like a carousel: the active page
  title ("Home", "Meet", "Discover", "Messages") is centered, bold and large,
  while the *edges of the neighbouring titles* are visible at the screen edges
  (e.g. "…over   **Home**   Mes…"). The strip scrolls with a parallax factor tied
  to the horizontal page swipe (title strip moves slower than the page content —
  in the Figma "Swipe" frames the incoming page slides over while titles slide
  proportionally).
- Home is the center page and the initial page.
- The Home page is titled **"Home"** when not discoverable and **"Meet"** when a
  discoverable session is active (same slot in the carousel).
- Sub-screens (chat, profile, settings, requests-full, find-person, pricing) are
  pushed on top of the shell as normal routes.

---

## 3. Sign-up flow (8 screens)

Order: Splash → Onboarding → Basics → OTP → Profile → Photo → Verifying → Home.

### 3.1 Splash
Full-bleed red→black vertical gradient, centered MetAfter swirl logo.
Auto-advances (~2s) to Onboarding (or straight to Home if session exists).

### 3.2 Onboarding ("Discover who's around you!")
Red gradient fading to black at the bottom. "MetAfter" wordmark top-center.
Middle: floating collage of circular avatars (varied sizes — existing
`discover_avatar_collage.dart`). Heading: **"Discover who's around you!"**;
sub-line: "No Awkward Intros, No Missed Connections." Bottom: red **Get Started**.

### 3.3 Sign Up / Start — "What should I call you?"
White. Red wordmark top-center. Title: **"What should I call you?"**
Fields: `Name` (e.g. "Luna Ray"), `Email ID` ("lunaray@gmail.com"), a centered
"or" divider, `Phone No` with country-code prefix ("+91 | 7562086805").
Email **or** phone — one contact channel is enough. CTA: **Next** (disabled until
name + one valid contact).

### 3.4 Sign Up / OTP — "Almost there…"
Subtext: "We sent a verification code to your email id lunaray@gmail.com" (or
"…to your phone no +91…"). Six individual bordered OTP boxes. CTA: **Continue**.
Auto-submit when 6 digits entered is acceptable; keep Continue as fallback.

### 3.5 Sign Up / Professional profile — "Let's complete your profile"
Fields: `Name` (prefilled), `Your Role` (dropdown — "Working Professional",
Student, Founder, Freelancer, Other), `Designation` ("UI / UX Designer"),
`Company Name` ("Techinorm"), `Professional Introduction` (multiline, placeholder
"This is how you'll be introduced to others."). CTA: **Next**.

### 3.6 Sign Up / Photo — "Let's add a profile photo"
Centered circular avatar placeholder with **red ring**, person glyph. Below:
live preview of the profile card — name bold, "UI/UX Designer – Techinorm",
the professional introduction, and helper copy: "A clear photo helps people
recognize and trust you during introductions." CTA: **Add Photo** (camera /
gallery picker). After picking, photo fills the ring, CTA becomes **Next**.

### 3.7 Sign Up / Verifying — "Verifying.."
Same layout, photo in ring. Copy: "We're verifying your photo. You can continue
while we verify your photo in the background." CTA: **Done** → Home. Photo
verification (selfie-match) runs in the background; the profile gets a
"verified" badge when it completes. Verification must not block entry.

### 3.8 Landing
Arrives on **Home**, not-discoverable state, with the pull-up affordance visible.

---

## 4. Home / Meet page (center of the shell)

### 4.1 Not discoverable (Home)
Dark background. Small pill toggle at top-right of the bar (quick discoverable
toggle). Center: **your avatar bubble** with ring; a small gear glyph sits on
the bubble's edge → opens **Settings**. Below:

- **"You are not discoverable"** (bold, white)
- "Tap to connect with people nearby" (grey)
- Light **"Let's Go!"** button
- Two setting rows (label left, red underlined value + chevron right):
  - "Discoverable for the next  **4 hrs ⌄**" → duration picker (30 min / 1 hr / 2 hrs / 4 hrs / 8 hrs)
  - "Set Distance  **2 mts ⌄**" → distance budget picker (2 mts / 5 mts / 10 mts)
- A **red glow gradient** rises from the bottom half.
- Bottom-center: pull-up chevron (Lottie `pull-up.json`) → connection-requests sheet (§7).

### 4.2 Discoverable (Meet)
Tapping **Let's Go!** starts a session: background animates **red→green
gradient** (bottom half glows green), title in the strip becomes **"Meet"**.

- Center: your avatar bubble; radar **ripple** animation pulsing outward
  (`ripple.json`).
- Nearby people appear as **floating avatar bubbles** around yours, each with a
  small distance chip ("1 mtr", "0.7 mtr", "0.5 mtr"). Bubbles drift gently
  (float animation), appear with a scale+fade pop, disappear with fade when lost.
  Radial placement ∝ estimated distance; angle stable per-peer (hash of id).
- **"You are discoverable"** (bold) and **"Time Remaining: 04:00"** countdown
  (h:mm or mm:ss as appropriate; live tick).
- Red **End Session** button → confirm → back to 4.1 (green fades to red,
  `inward-ripple.json` accent is appropriate here).
- Tapping a **bubble** → Nearby Person Profile (§5).
- Session auto-ends when the countdown reaches zero.

---

## 5. Nearby Person Profile ("Bubble Tap")

Full-screen red gradient page. Back arrow, wordmark. Centered avatar with ring,
**name** ("Luna Ray"), role line ("VP, Sales – SaleSail"), bio paragraph ("I am a
brand salesperson who focuses on clarity and emotional connections of clients").
Bottom: **Connect** button.

- Connect → **invitation note modal** (§6.3) when applicable → request sent →
  button becomes "Request Sent" (disabled).
- Data comes from the peer's BLE profile card (already cached at sighting time).

---

## 6. Discover page ("People You Crossed Paths")

Left page of the shell. White. Header: **Discover**, subtitle "People You
Crossed Paths". Top-right icons: **view toggle** (hamburger = list / grid glyph
= card) and **calendar/search**. A **date band** ("Today - 25 Jan, 2026") on a
pink tint; calendar icon opens a date picker to jump to a day's history.

### 6.1 Card view (grid glyph)
A horizontally swipeable **card carousel**, one profile card at a time:
rounded card with red gradient glow border, avatar, name, role – company, bio,
red **Connect** button inside the card. Page dots below. Newest sighting first.

### 6.2 List view (hamburger glyph)
Time-grouped rows, newest first: left column = sighting time ("4:28 PM"),
avatar, name ("Koby Stone"), role/company two-liner ("SVP Engineering",
"InnoVision"), right: red **Connect** pill. Rows for people already requested
show a disabled "Sent" state.

### 6.3 Invitation note modal — "Add a note to your invitation"
Dialog over a dimmed background: text field (placeholder "Ex: We met at the expo
…"), actions **Skip** (plain) and **Send** (red). Notes are a Pro feature with a
free quota — over quota, show the Pro upsell (§11.3) instead of sending.

Data: 100% local — the encounters ledger written by the BLE scanner. Each entry:
peer profile card snapshot (name/role/company/bio/photo thumb), first/last seen
time, estimated distance. Retention 30 days locally (user-configurable later).

---

## 7. Connection requests (pull-up sheet + full page)

### 7.1 Pull-up sheet (over Home)
Dragging the chevron up slides a white rounded-top sheet over the dark Home:
header **Connect** / "Connection Request". Rows: avatar, name ("Liam Smith"),
role/company ("CTO", "TechCorp"), red **Accept** pill, grey **Decline** pill.
Empty state: **"No new friend request"** single line at the bottom.

### 7.2 Full page
The sheet expands (drag to top) into a full-screen white page with the same
list. Accept → the two devices complete a key exchange; a chat thread is
created; if the peer is still in BLE range, offer **Find Person** (§8).
Decline → row disappears (decline is silent; no notification to sender).

An incoming request while the app is open animates the pull-up chevron
(pulse) and shows a subtle badge; in background it arrives as a push.

## 8. Find Person ("Find Directions")

Red/dark gradient page. Top: small profile chip of the person (avatar, name,
role). Center: **large white arrow** rotating to point toward the person, and
distance text: **"20 ft to your right"**. Bottom: **Done**.

Implementation note: BLE phones cannot measure true angle-of-arrival. Direction
is estimated from the RSSI gradient as the user moves/rotates (hot/cold) plus
compass heading; the copy shows estimated distance ("20 ft") and a coarse
relative direction ("to your right" / "ahead" / "behind you"). The arrow eases
(rotation animation) rather than jumping. Accuracy caveats are acceptable; the
feature is a guided "warmer/colder" experience.

---

## 9. Messages page

Right page of the shell. White. Header **Messages** + search icon (filters the
list as you type). Section label **Chats**. Rows: avatar, name ("Candice Wue"),
preview ("You: Okay, Let's Go." — prefix "You: " when the last message is mine),
right-aligned relative age ("3h", "6h", "12h", "22h"). Unread rows: bold name +
red unread dot.

- **Swipe left** on a row → red **Archive** action (with icon) slides in;
  confirming archives locally. An "Archived" collapsible section sits at the
  list bottom when non-empty.
- Tap → Chat (§10).

---

## 10. Chat page

Header: avatar + name + presence ("nearby" when peer currently in BLE range),
call icons (audio, video), kebab menu. Bubbles: peer grey/left, mine red/right,
with timestamps; long-press → emoji reactions (reaction chip attaches to the
bubble). Input bar: text field, attachment, send.

Kebab menu (slides over a red gradient header — matches "Message Chat Page"
variant): **Video Call**, **Audio Call**, **Disappearing Messages** (off / 24h /
7d), profile summary, and a red **Disconnect** button (removes the connection,
wipes the shared keys, thread stays locally until deleted).

Transport: BLE direct when in range; E2E-encrypted relay via MQTT when not
(§ backend doc). Disappearing messages are deleted locally on both ends after
the TTL. Calls are a later milestone: the UI entries exist (call screen is
already built) but real WebRTC signalling is out of scope for this phase —
document as stub.

---

## 11. Settings & Pro

### 11.1 Settings page (gear on the Home bubble)
White sheet: profile header (avatar, name, role – company, red **See Profile**
link). Items:

1. **Set Mood Ring** — value chip; options **Networking / Friends / Catchup /
   Just Checking**. The mood ring is a colored ring around your avatar bubble,
   broadcast in the BLE advertisement so others see your intent color.
   (Networking = red, Friends = amber, Catchup = green, Just Checking = blue.)
2. **Share Profile** — share sheet (deep link / QR later).
3. **Language** — value "English".
4. **Time Format** — "12hr" / "24hr".
5. **Accessibility** — larger text, reduce motion.
6. **Privacy & Security** — §11.2.
7. **Discoverable Time** — default session duration.
8. **Proximity Distance** — default distance budget.
9. Bottom: **Get MetAfter Pro** button → Pricing (§11.3).

### 11.2 Privacy & Security
Toggle list (persisted locally): Read Receipts, Typing Indicator, Video Call,
Audio Call, Disappearing Messages default, Show Company Name, Show Designation,
Incognito Scan (scan without advertising), Block List entry.

### 11.3 Pricing / Pro
"We believe MetAfter should be accessible to all. Simple, transparent pricing."
Toggle **Annual pricing (Save 20%)**. Card: **$10/mth Pro Plan** (billed
annually). Feature checklist: access to all basic features, unlimited connection
requests, invitation notes to individual users, priority chat & email support.
CTA **Get Started**. The same card appears as an in-chat/in-flow upsell modal
(**Upgrade to Pro / Continue with Pro**) when a free limit is hit (invitation
notes, request quota). Purchase wiring (IAP) is out of scope this phase — tapping
records intent and shows "coming soon"; gate logic is real.

---

## 12. Animation inventory

| # | Where | Animation |
| --- | --- | --- |
| A1 | Shell | Horizontal page swipe with parallax title strip |
| A2 | Home→Meet | Background gradient cross-fade red→green (~600ms ease) |
| A3 | Meet | Outward ripple radar pulse behind your bubble (Lottie `ripple.json`, loop) |
| A4 | Meet | Peer bubble enter: scale 0.6→1 + fade, ~350ms spring; exit: fade 250ms |
| A5 | Meet | Peer bubbles idle float (slow sine drift ±6px) |
| A6 | Meet | Distance chips update with tween (position eases as distance changes) |
| A7 | Home | Pull-up chevron idle bounce (Lottie `pull-up.json`); pulse on new request |
| A8 | Requests sheet | Bottom-sheet drag with snap points: peek / half / full |
| A9 | Discover cards | Card carousel swipe + page-dot sync |
| A10 | Messages | Row swipe-left reveals Archive with red slide-in |
| A11 | Chat | Bubble send: slide-up+fade; reaction pop (scale overshoot) |
| A12 | Find Person | Arrow rotation eased (~400ms), distance text count-tween |
| A13 | Session end | Green fades back to red; `inward-ripple.json` accent |
| A14 | Countdown | mm:ss ticking, final 30s pulses red |

Respect "reduce motion" (Accessibility setting): disable A3–A5 drift and A7.

---

## 13. Functional ground rules (local-first)

1. **No personal data at rest in the cloud.** Profiles, encounters, requests,
   connections, and messages persist only in the device DB (SQLite) and secure
   storage (keys). The backend keeps: account identifier, public keys, push
   token, verification badge — plus a TTL'd mailbox of E2E ciphertext in flight.
2. **BLE is the primary channel**: advertising + scanning during sessions; GATT
   for profile cards, requests, and in-range messages.
3. **Relay is the fallback**: MQTT/push carries E2E-encrypted envelopes when
   peers are out of range (accepting a crossed-paths connect hours later).
4. **Everything on the Discover page comes from the local encounters ledger.**
5. Uninstalling the app = losing local data (documented; export/backup later).
