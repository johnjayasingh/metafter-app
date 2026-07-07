# MetAfter — Implementation Guide

> The complete record of the local-first/BLE-first build: what was built, how it
> works, how to run it, what was verified, and what still needs a device in hand.
> Companion documents: [DESIGN_SPEC.md](DESIGN_SPEC.md) (the Figma-derived
> product spec) and [`metafter-backend/ARCHITECTURE.md`](../../metafter-backend/ARCHITECTURE.md)
> (the system architecture).
> Last updated: 2026-07-07.

---

## 1. What MetAfter is

A Bluetooth-proximity professional networking app. You go discoverable for a
time-boxed session ("Let's Go", 4 hrs, 2 m radius), nearby MetAfter users appear
as bubbles on a radar, everyone you crossed paths with lands in a local ledger
("Discover — People You Crossed Paths"), you send connection requests (with an
optional invitation note), and once connected you chat — end-to-end encrypted,
over BLE when you're near each other and via a blind cloud relay when you're not.

**The one rule (ARCHITECTURE.md §0):** user data lives on the device. The cloud
holds only: your account id + phone (Cognito), your *public* keys + push token +
verified badge (directory table), and E2E ciphertext in flight (mailbox table,
72 h TTL, deleted on delivery ACK). The server cannot read messages, profiles,
your crossed-paths history, or your social graph — they never leave the phone
in readable form.

## 2. What was built (this effort)

| Layer | What | Where |
| --- | --- | --- |
| Product spec | Full transcription of the Figma boards: every screen, state, flow, 14-item animation inventory | `docs/DESIGN_SPEC.md` |
| Architecture | v2 rewrite: local-first pivot, BLE protocol, E2E crypto, transport-only cloud | `metafter-backend/ARCHITECTURE.md` |
| Domain contracts | Shared models (ProfileCard, Encounter, ConnectionRequest, Connection, ChatMessage, ThreadSummary, MoodRing…) | `lib/core/domain/models.dart` |
| Crypto | Ed25519 identity + X25519 agreement + HKDF + ChaCha20-Poly1305 sealing, rotating BLE ephemeral ids, canonical-JSON signatures; keys in Keychain/Keystore | `lib/core/crypto/crypto_service.dart` |
| Local DB | sqflite `metafter.db` (7 tables) + reactive repositories (profile, encounters, requests, connections, messages/threads, settings) | `lib/core/db/` |
| Proximity | `ProximityEngine` contract + **BleProximityEngine** (advertise + scan + GATT, real plugins) + **SimulatedProximityEngine** (10 personas with real crypto, drives local/dev flavors) + distance/direction estimators | `lib/core/proximity/` |
| Transport | `RelayTransportClient`: MQTT-over-WSS (SigV4/IoT Core) + REST mailbox/directory, envelope dedupe, ACK-after-emit, backoff reconnect, polling fallback | `lib/core/transport/` |
| Services | SessionService (discoverable lifecycle), ConnectionService (BLE-first request/accept/decline/disconnect + Pro gating), MessageService (E2E send/receipts/reactions/disappearing), InboundHandler + EnvelopeRouter (single path for BLE and relay arrivals), composition root | `lib/core/services/` |
| Screens | Every screen rewired from hardcoded mocks to the service layer, matching the design animations | `lib/features/**` |
| Backend | Rebuilt transport-only: 2 DynamoDB tables (directory, mailbox+TTL), 8 routes, tightened IoT policy, ephemeral photo verification, account deletion; local Docker stack mirrors it | `metafter-backend/` |
| Tests | 126 Flutter tests (unit + widget) and 19 backend Jest tests; full E2E transport smoke against the local stack | `test/`, `metafter-backend/test/` |

## 3. Repository tour

### App (`metafter-app/lib`)

```
core/
  domain/models.dart        Shared value objects — the only person/request/message types
  crypto/crypto_service.dart  Identity keys, sealing, signing, EIDs (singleton)
  db/                       app_database.dart (schema v1) + *_repository_impl.dart
  proximity/                proximity_engine.dart (contract) + ble/simulated engines
  transport/                envelope.dart, transport_client.dart (contracts),
                            relay_api.dart, relay_transport_client.dart
  services/                 services.dart + app_services.dart (contracts/locator),
                            *_impl.dart, inbound_handler, envelope_router,
                            bootstrap_services.dart (composition root)
  widgets/                  peer_avatar.dart, pro_upsell.dart (+ legacy form lib)
  utils/time_format.dart    Relative ages, clocks, date bands, countdowns
features/
  onboarding/  splash + "Discover who's around you!"
  signup/      basics → OTP → profile → photo → selfie(liveness) → verifying
  home/        home_shell (swipe carousel + Home/Meet + radar + pull-up sheet),
               discover_history, nearby_person_profile, connected_profile,
               find_person, connect_requests, all_messages, chat, call,
               profile_settings, privacy_security, pricing
```

Data-flow rule enforced throughout: **screens → `AppServices.I` (services +
repositories) → engine/transport/DB**. No screen touches sqflite, BLE, or HTTP
directly, and there are no per-screen person classes or mock lists left.

### Backend (`metafter-backend`)

- `lib/stacks/` — CDK: auth (Cognito phone-OTP custom auth, unchanged), data
  (directory + mailbox tables only), iot (per-user inbox-scoped MQTT policy),
  storage (verification scratch bucket, 1-day lifecycles), api (8 routes).
- `src/handlers/` — auth trio, `directory`, `mailbox`, `verification`,
  `account`. The old profile/discovery/connections/messaging handlers are gone.
- `src/local/` + `docker-compose.yml` — Express mirror of API Gateway,
  DynamoDB-Local (in-memory), MinIO, Mosquitto; `X-Dev-User-Id` header auth.

## 4. How each flow works

### Sign-up (§3 of the spec)
Phone number → Cognito custom-auth OTP over SMS (define/create/verify lambda
trio; email field collected but decorative — email auth is a spec gap, see §8).
Profile details and photo stay on the device. At the Verifying step the app:
saves the local `MyProfile` row → publishes public keys to `/v1/directory` and
connects the relay → runs photo verification (photo + Rekognition Face Liveness
selfie compared **server-side, then both are deleted**; only a signed
`verified` badge comes back) → `Done` is never blocked by any of this.

### Discoverable session (Home ⇄ Meet)
`SessionService.start()` reads your settings (duration 30 min–8 hrs, distance
2/5/10 m, mood ring, incognito), builds a privacy-filtered signed profile card,
and starts the engine: BLE advertising (service UUID + service data = rotating
8-byte EID + flags + mood + txPower) plus filtered scanning. The Home card
crossfades red→green, the title strip flips to **Meet**, the countdown ticks,
and nearby peers stream onto the radar (distance from RSSI path-loss with EMA
smoothing). Ending (button, countdown, or dispose) stops everything. Incognito
scans without advertising.

### Crossed paths (Discover)
When the scanner first sights a peer it GATT-reads their profile card (chunked)
and writes an **encounter** to the local ledger (merge window 30 min, closest
distance kept, 30-day local retention sweep). The Discover page renders purely
from this ledger: date band + calendar picker over days-with-encounters, list
view (sighting time / avatar / name / role / Connect) and swipeable card view
with page dots.

### Connecting
Connect (radar profile, Discover row/card) → invitation-note modal (Skip/Send)
→ `ConnectionService.sendRequest`: Pro gate first (5 free requests/day, 1 free
note — over quota shows the Upgrade-to-Pro sheet), then **BLE GATT write if the
peer is in range, relay envelope otherwise**. The recipient's pull-up sheet
(and the full Connection Request page) shows Accept/Decline. Accept persists
the connection (with your current mood as `moodAtMeet`), replies BLE-first with
relay fallback, and offers **Find Person** when the peer is still in range.
Decline is silent by design. Both sides' cards carry Ed25519-signed identity;
every request/response is signature-verified and `card.sub == from` is enforced
against identity substitution.

### Messaging
Chat threads are strictly 1:1, keyed by the peer's account id. Every message is
sealed to the peer's X25519 key (ephemeral-static ECDH → HKDF → ChaCha20-
Poly1305) and signed; the **same envelope format** rides BLE frames when nearby
and the relay when not, and both arrival paths converge on one inbound handler
(dedupe by message id — double delivery over both channels is safe). Receipts
drive the ✓/✓✓/✓✓-read ticks (read receipts honor the privacy toggle), emoji
reactions ride receipt envelopes, disappearing messages (off/24 h/7 d per
thread) are deleted locally on both ends by a minute sweeper. Archive is a
local flag with swipe gestures. Presence ("nearby" chip) is live BLE range.
Audio/video call screens exist as an honest preview — media transport is a
later milestone.

### Find Person
BLE gives no true angle-of-arrival, so the arrow is a guided hot/cold
estimator: distance slope over a ~3 s window decides warmer/colder, fused with
the compass heading, with low-pass filters on everything (quadrant-level
accuracy, documented in DESIGN_SPEC §8). Signal-lost state offers Retry.

### Settings, privacy, Pro
Every setting persists in the local DB and is *the same ValueListenable* the
shell reads — changing "Discoverable Time" in Settings changes the Home dropdown
live. Mood ring (Networking/Friends/Catchup/Just Checking) colors your avatar
ring and rides the BLE advertisement. Privacy toggles shape the broadcast card
(name visibility → full/first-name/initials, company/designation gating) and
gate calls/receipts. Pro gating is real (request/note quotas → upsell sheet);
purchase itself intentionally shows "coming soon" (no IAP wiring this phase).

### The relay (cloud), end to end
`POST /v1/mailbox` validates the envelope shape (kind enum, ≤64 KB ciphertext),
stores it under the recipient with a 72 h TTL, publishes it to the recipient's
IoT topic (`metafter/<stage>/u/<sub>/inbox` — the IoT policy only lets a user
subscribe to *their own* inbox), and fires a **content-free** push ("You have
something waiting on MetAfter"). Recipients ACK (`DELETE /v1/mailbox/{id}`)
after processing, which erases the ciphertext. Undelivered envelopes expire.

## 5. Running it

### Local (no AWS at all)

```bash
# 1. Backend stack: Express API :3000, DynamoDB-Local :8000 (in-memory),
#    MinIO :9000/:9001, Mosquitto :1883/:9002
cd metafter-backend
npm install && npm run build
docker compose up -d          # init container creates tables + bucket

# Smoke it (dev auth = X-Dev-User-Id header):
curl -s -X POST localhost:3000/v1/directory -H 'X-Dev-User-Id: alice' \
  -H 'Content-Type: application/json' \
  -d '{"edPub":"ZWQ=","xPub":"eA=="}'

# 2. App — local flavor uses the SimulatedProximityEngine (10 personas that
#    appear on the radar, send requests, accept yours, and chat back with real
#    E2E crypto) + mailbox polling (no MQTT/SigV4 locally).
cd metafter-app
flutter pub get
./run-local.sh                # = flutter run -t lib/main_local.dart
```

The **dev** flavor (`./run-dev.sh`) also uses the simulated engine but talks to
the deployed AWS dev stack (Cognito OTP, real relay over IoT MQTT). **uat/prod**
flavors use the real `BleProximityEngine` and need their environment values
filled in `lib/core/config/environment_config.dart` (currently TODO).

### Tests

```bash
cd metafter-app && flutter analyze && flutter test    # 126 tests, 0 analyzer issues
cd metafter-backend && npx tsc --noEmit && npm test   # 19 tests
```

### Deploying the backend

```bash
cd metafter-backend
npx cdk synth -c env=dev            # verified clean
npm run deploy:dev                  # deploys auth/data/storage/iot/api
# prod: pass a real badge secret:  -c badgeSecret=<strong secret>
```

⚠️ Deploying over the old v0.1 stacks **deletes** the seven legacy tables
(users/sessions/encounters/connections/requests/messages/devices) outside prod
— that is the intended pivot, but it is destructive.

## 6. Verification status

Verified in this environment:
- `flutter analyze`: **0 issues** (lib + test). `dart analyze`: clean on every new module.
- **126 Flutter tests**: crypto round-trips (seal/open, sign/verify, sim-persona
  interop), DB merge/unread/sweep logic, Pro-gating decision table, inbound
  authentication (identity substitution and non-connection messages dropped),
  simulated engine choreography, and widget tests for shell, discover,
  requests, messages, chat, and settings.
- **19 backend tests**: directory upsert/rotation, mailbox lifecycle, envelope
  validation rejections, verification happy/failure paths (badge only on
  success; photo deleted either way), account deletion.
- **Live local E2E**: directory publish → key fetch → mailbox deposit →
  **MQTT fanout observed on the recipient's inbox topic** → drain → ACK →
  empty → account delete → 404.
- `cdk synth`: exactly the 8 intended Cognito-authorized routes, two tables.

Needs physical devices (cannot be exercised here):
- Two-phone BLE: advertise/scan/GATT card exchange, request/accept over GATT,
  chunked reads on real MTUs, Android 12+ permission prompts, iOS peripheral
  behavior (see §8), EID rotation mid-session.
- MQTT-over-WSS against real IoT Core from the app (SigV4 URL logic is
  salvaged from previously working code; endpoint policy is deployed).
- Rekognition Face Liveness on iOS requires the one-time Xcode step of adding
  the `amplify-ui-swift-liveness` SPM package (degrades to "verify later"
  without it; Android is fully wired).

## 7. Security model (what an attacker gets)

- **Server compromise**: phone numbers (Cognito), public keys, push tokens,
  who has ciphertext waiting (recipient ids + sizes/timing), ≤72 h of
  undelivered ciphertext it cannot decrypt. No messages, no profiles, no
  social graph, no location/encounter history.
- **BLE passive observer**: rotating 8-byte EIDs (15 min HMAC windows from a
  device-only seed) — no stable identifier to track across windows; profile
  cards are only served while you are *deliberately* discoverable.
- **Peer authenticity**: cards are self-signed (Ed25519); envelopes/frames are
  signed and sealed; the router enforces `card.sub == from` and drops anything
  unverifiable; message senders must be established connections.
- **Verified badge**: server-side HMAC over `verified:<sub>` issued only after
  liveness + face match; photos deleted immediately after the comparison.
- Trade-offs accepted this phase (documented in ARCHITECTURE.md): no double
  ratchet (no per-message forward secrecy), SQLite not yet SQLCipher-encrypted
  at rest, badge secret is a Lambda env var rather than KMS/Secrets Manager.

## 8. Known limitations & open items

1. **flutter_blue_plus licensing** — v2.3.3 requires a paid license for
   commercial use; the code passes `License.free`. Resolve before shipping
   (or swap the central role onto `bluetooth_low_energy`, which is BSD).
2. **iOS advertising** — CoreBluetooth cannot put service data in
   advertisements: iOS-advertised peers reveal EID/flags/mood only after the
   GATT card read; mood ring defaults to Networking until then. Background
   BLE (state restoration, foreground service polish) is roadmap.
3. **Email auth** — the spec allows email *or* phone; only phone-OTP exists.
   The email field is collected but decorative.
4. **No retry queue** — a message that fails both BLE and relay stays in
   status "sending" with no automatic retry; accept responses are best-effort
   (no redelivery scheduler).
5. **Calls are a preview** — the call screens simulate; no WebRTC.
6. **Purchases** — Pro gates are real; checkout intentionally "coming soon".
7. **Push is stubbed** — the mailbox handler calls the push port, but SNS
   Platform Applications (APNs/FCM) are not provisioned; live MQTT + drains
   cover foreground delivery meanwhile.
8. **No multi-device / backup** — uninstalling loses local data (explicit
   product stance; encrypted export is a roadmap item).
9. **uat/prod configs** — `environment_config.dart` values are TODO until
   those stacks are deployed.
10. **Mood-ring/incognito changes mid-session** apply from the next session.

## 9. Design-spec traceability

Every numbered section of `DESIGN_SPEC.md` maps to code: §2 shell/carousel →
`home_shell.dart` (_PeekCarousel/_PageTitleStrip kept from the original build);
§3 sign-up → `features/signup/*`; §4 Home/Meet + A2–A7/A13–A14 animations →
`home_shell.dart` (gradient crossfade, radar enter/float/ease, countdown pulse,
pull-up Lottie); §5 bubble-tap profile → `nearby_person_profile_screen.dart`;
§6 Discover + A9 → `discover_history_screen.dart` + `invite_note_dialog.dart`;
§7 requests sheet/page → `home_shell.dart` + `connect_requests_screen.dart`;
§8 Find Person + A12 → `find_person_screen.dart` + `direction_estimator.dart`;
§9 Messages + A10 → `all_messages_screen.dart`; §10 chat + A11 →
`chat_screen.dart`; §11 settings/privacy/Pro → `profile_settings_screen.dart`,
`privacy_security_screen.dart`, `pricing_screen.dart`, `pro_upsell.dart`;
§12 reduce-motion honored by every looping animation; §13 ground rules → the
architecture itself.

## 10. Roadmap (post-this-phase)

1. Double-ratchet (per-message forward secrecy) for relay chats.
2. SQLCipher for the local DB; encrypted export/backup with a user passphrase.
3. WebRTC calls (signalling as another envelope kind).
4. IAP + server-signed Pro entitlement in the directory row.
5. APNs/FCM platform applications for real push.
6. Background BLE strategies; UWB ranging where hardware allows (real Find
   Person bearings).
7. Email OTP auth channel; OTP resend/cooldown UX.
8. Block/report flows.
