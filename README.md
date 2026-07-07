# MetAfter

Bluetooth-proximity professional networking, **local-first**: discovery and
connections happen device-to-device over BLE, all user data lives on the phone
(SQLite + Keychain/Keystore), and the cloud is only an identity + E2E-encrypted
transport layer.

**Start here:**

- [docs/GUIDE.md](docs/GUIDE.md) — implementation guide: what was built, how
  every flow works, how to run it, verification status, known limitations.
- [docs/DESIGN_SPEC.md](docs/DESIGN_SPEC.md) — the Figma-derived product spec
  (screens, states, animation inventory).
- [`../metafter-backend/ARCHITECTURE.md`](../metafter-backend/ARCHITECTURE.md)
  — system architecture (BLE protocol, E2E crypto, transport-only cloud).

## Project layout

```text
lib/
  main.dart / main_dev.dart / main_uat.dart / main_local.dart   # flavor entrypoints
  core/
    domain/       # Shared value objects (ProfileCard, Encounter, ChatMessage…)
    crypto/       # Identity keys, sealing, signing, BLE ephemeral ids
    db/           # sqflite schema + reactive repositories
    proximity/    # ProximityEngine: BLE (real) + Simulated (local/dev) engines
    transport/    # E2E envelope, relay client (MQTT + mailbox REST)
    services/     # Session/Connection/Message orchestration + AppServices locator
    auth/         # Cognito passwordless phone-OTP
    config/       # EnvironmentConfig per flavor
    network/      # Dio client, verification API
    theme/ widgets/ utils/
  features/
    onboarding/ signup/ home/     # every screen wired to the service layer
```

## Run

```bash
flutter pub get

./run-local.sh    # simulated nearby people + local Docker backend (see guide §5)
./run-dev.sh      # simulated nearby people + deployed AWS dev stack
flutter run -t lib/main.dart      # PROD (real BLE engine; config TODO)
```

Quality gates: `flutter analyze` (0 issues) and `flutter test` (126 tests).

## Build flavors

See `BUILD_INSTRUCTIONS.md`, `BUILD_FLAVORS_GUIDE.md`, and the various
`build-*.sh` scripts at the repo root.

## Renaming reminder

The Dart package name is `metafter`. Android `applicationId` and iOS bundle
identifier still reference the previous project — update them under
`android/app/build.gradle.kts` and the Xcode project before publishing.
