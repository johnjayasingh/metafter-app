# Build Configuration Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Digital Will Project                          │
│                  Multi-Environment Setup                         │
└─────────────────────────────────────────────────────────────────┘

┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   Environment     │   │   Environment     │   │   Environment     │
│       DEV         │   │       UAT         │   │   PRODUCTION      │
├───────────────────┤   ├───────────────────┤   ├───────────────────┤
│                   │   │                   │   │                   │
│ Entry Point:      │   │ Entry Point:      │   │ Entry Point:      │
│ lib/main_dev.dart │   │ lib/main_uat.dart │   │ lib/main.dart     │
│                   │   │                   │   │                   │
│ API:              │   │ API:              │   │ API:              │
│ dev-api.url.com   │   │ uat-api.url.com   │   │ api.url.com       │
│                   │   │                   │   │                   │
└───────────────────┘   └───────────────────┘   └───────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                       lib/core/config/                           │
│                   environment_config.dart                        │
│         (Manages API URLs and environment settings)              │
└─────────────────────────────────────────────────────────────────┘
         │                       │                       │
    ┌────┴────┐             ┌────┴────┐           ┌────┴────┐
    │         │             │         │           │         │
    ▼         ▼             ▼         ▼           ▼         ▼
┌───────┐ ┌───────┐   ┌───────┐ ┌───────┐   ┌───────┐ ┌───────┐
│Android│ │  iOS  │   │Android│ │  iOS  │   │Android│ │  iOS  │
└───────┘ └───────┘   └───────┘ └───────┘   └───────┘ └───────┘
    │         │             │         │           │         │
    ▼         ▼             ▼         ▼           ▼         ▼
  .apk      .ipa          .apk      .ipa        .apk      .ipa
  .aab                    .aab                   .aab

┌─────────────────────────────────────────────────────────────────┐
│                         Android Builds                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DEV                    UAT                   PRODUCTION         │
│  ───────────────────────────────────────────────────────────    │
│  Package:               Package:              Package:           │
│  .metafter.dev       .metafter.uat      .metafter       │
│                                                                  │
│  App Name:              App Name:             App Name:          │
│  "Metafter DEV"       "Metafter UAT"      "Metafter"       │
│                                                                  │
│  Command:               Command:              Command:           │
│  flutter build apk      flutter build apk     flutter build apk  │
│    --flavor dev         --flavor uat          --release          │
│    -t lib/main_dev.dart -t lib/main_uat.dart                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          iOS Builds                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DEV                    UAT                   PRODUCTION         │
│  ───────────────────────────────────────────────────────────    │
│  Bundle ID:             Bundle ID:            Bundle ID:         │
│  .metafter.dev       .metafter.uat      .metafter       │
│                                                                  │
│  Display Name:          Display Name:         Display Name:      │
│  "Metafter DEV"       "Metafter UAT"      "Metafter"       │
│                                                                  │
│  Scheme:                Scheme:               Scheme:            │
│  dev                    uat                   Runner             │
│                                                                  │
│  Command:               Command:              Command:           │
│  flutter build ios      flutter build ios     flutter build ios  │
│    --flavor dev         --flavor uat          --release          │
│    -t lib/main_dev.dart -t lib/main_uat.dart                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Build Automation Script                       │
│                     ./build-flavors.sh                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Usage:                                                          │
│  ──────                                                          │
│  ./build-flavors.sh [platform] [environment] [build-type]       │
│                                                                  │
│  Examples:                                                       │
│  ─────────                                                       │
│  ./build-flavors.sh android dev apk                             │
│  ./build-flavors.sh android uat aab                             │
│  ./build-flavors.sh ios dev ipa                                 │
│  ./build-flavors.sh ios uat ipa                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Distribution Flow                           │
└─────────────────────────────────────────────────────────────────┘

    ┌────────────┐                    ┌────────────┐
    │   Build    │                    │   Build    │
    │   DEV      │                    │   UAT      │
    └──────┬─────┘                    └──────┬─────┘
           │                                 │
           ▼                                 ▼
    ┌────────────────────────────────────────────┐
    │         builds/ directory                   │
    │  ├── android/                               │
    │  │   ├── dev/                               │
    │  │   │   └── metafter-dev-timestamp.apk │
    │  │   └── uat/                               │
    │  │       └── metafter-uat-timestamp.apk │
    │  └── ios/                                   │
    └────────────────────────────────────────────┘
           │                                 │
           ▼                                 ▼
    ┌────────────┐                    ┌────────────┐
    │ Distribute │                    │ Distribute │
    │  to Dev    │                    │  to UAT    │
    │  Testers   │                    │  Testers   │
    └────────────┘                    └────────────┘
           │                                 │
           ├─────────────┬───────────────────┤
           ▼             ▼                   ▼
    ┌──────────┐  ┌──────────┐      ┌──────────┐
    │  Email/  │  │ Firebase │      │TestFlight│
    │  Drive   │  │   App    │      │(iOS) or  │
    └──────────┘  │  Distrib │      │Play Store│
                  └──────────┘      └──────────┘

┌─────────────────────────────────────────────────────────────────┐
│               Same Device Installation                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📱 Phone Home Screen                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │   ┌────────┐    ┌────────┐    ┌────────┐              │   │
│  │   │  📱    │    │  📱    │    │  📱    │              │   │
│  │   │ Will   │    │ Will   │    │ Will   │              │   │
│  │   │ Cloud  │    │ Cloud  │    │ Cloud  │              │   │
│  │   │  DEV   │    │  UAT   │    │        │              │   │
│  │   └────────┘    └────────┘    └────────┘              │   │
│  │                                                          │   │
│  │   All 3 versions can be installed at the same time!    │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Key Features                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ Separate API endpoints per environment                      │
│  ✅ Unique package/bundle IDs for parallel installation         │
│  ✅ Clear app naming to identify builds                         │
│  ✅ Automated build scripts                                     │
│  ✅ Easy distribution to testers                                │
│  ✅ Environment-specific configurations                         │
│  ✅ Debug banner for non-production builds                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```
