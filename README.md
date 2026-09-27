# Ankur (अंकुर) — Voice-First ECCE Developmental Copilot

> **Ankur AI · ECCE Developmental Copilot** — a voice-first, offline-ready Flutter app that helps **Anganwadi workers** observe, track, and support early-childhood development (age 3–6) in their own language.

An Anganwadi worker speaks a child observation out loud. Ankur transcribes it, tags it against the six **NCF-FS 2022** developmental domains, updates the child's development profile, and suggests a **Jadui Pitara** activity — then, when a child falls behind, it generates a pseudonymized **RBSK/ASHA referral** document. All on-device, in Hindi, Tamil, Gujarati, or English.

**Status: interactive prototype.** The speech pipeline is real (Deepgram Nova-2 on web); the domain classifier and the crypto layer are faithful simulations of the production design (TFLite model and real AES-GCM/HMAC respectively).

---

## The problem it solves

India's ~1.4 million Anganwadi workers run the world's largest early-childhood-care network, but they record child development on paper registers — observations are lost, milestones are never tracked across time, and developmental delays surface too late for early intervention.

Ankur turns the worker's *voice* into a structured developmental record:

- **Speak, don't write** — a 20-second spoken observation replaces a paper register entry.
- **Instant domain tagging** — the observation is mapped to the six NCF-FS 2022 domains.
- **A living development profile** — every child carries a 6-domain radar profile that updates with each observation, rolling up into **On Track / Needs Watch / Red Flag**.
- **A suggested next activity** — a Jadui Pitara activity for the observed domain, read aloud to the worker (TTS).
- **An escalation path** — when a child scores persistently low, Ankur generates a DPDP-compliant, pseudonymized RBSK/ASHA referral document to hand to the health worker.

---

## Feature set

| Area | What's implemented |
|------|--------------------|
| **Voice capture** | Mic → MediaRecorder → Deepgram Nova-2 REST transcription (en-IN, hi, ta, gu). Graceful word-by-word simulated fallback when mic is denied. |
| **Domain classification** | Multilingual keyword engine (en/hi/ta/gu) simulating the production TFLite INT8 model (<15 MB). 6 NCF-FS domains, multi-label output, sentiment + milestone boosts. |
| **Child records** | Roster with search, add/edit, per-child observation history, 6-domain radar chart, status tiering (On Track / Needs Watch / Red Flag). |
| **Jadui Pitara activities** | One curated activity per domain in 4 languages — index retrieval (never LLM generation), with TTS read-aloud. |
| **Referrals** | RBSK/ASHA referral document with pseudonymized header (DPDP), offline share. |
| **Consent & privacy** | First-launch consent screen, DPDP Act 2023 notice, pseudonymous IDs (`hmac_…`), crypto audit log showing what leaves the device. |
| **Offline-first** | Hive local storage, outbox sync counter, draft auto-save during recording (every 15 characters), full multilingual UI. |
| **Demo/pitch mode** | In-app pitch slides (pipeline, specs, privacy story) and a crypto sandbox panel — toggleable. |

## The pipeline

```
Worker speaks ──► Deepgram Nova-2 (REST) ──► transcript (4 languages)
                                          ──► TFLite-style domain classifier
                                                └─► 6 NCF-FS domains, multi-label
                                          ──► child development profile update
                                                └─► On Track / Watch / Red Flag
                                          ──► Jadui Pitara activity suggestion (TTS)
                                          ──► RBSK/ASHA referral (pseudonymized, DPDP)
```

## Screens

| Screen | Purpose |
|--------|---------|
| Consent | First-launch DPDP consent (blocks use until given) |
| Home | Class roster, search, status badges, sync/outbox status |
| Profile | 6-domain radar, observation history, referral entry point |
| Record | Pulsing mic UI, live transcript, simulated-voice toggle, draft restore |
| Result | Domain tags, editable transcript, Jadui Pitara activity + TTS, save |
| Referral | RBSK/ASHA handover document, offline share |
| Add Child | Enrollment with pseudonymous ID generation |
| Settings | Language (en/hi/ta/gu), sync, export, crypto sandbox toggle |

## Tech stack

- **Flutter** (Dart SDK ^3.9.2, Material 3, portrait-locked, seed `#0284C7`)
- **State:** `provider` · **Storage:** `hive` / `hive_flutter` (offline-first)
- **Speech:** `speech_to_text`, `flutter_tts`, `permission_handler`; web via `web/speech_bridge.js` → Deepgram Nova-2 REST
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux · **Web hosting:** Vercel (`vercel.json` builds Flutter web from the stable SDK)

## Project structure

```
lib/
├── main.dart                     # app entry, theme, orientation lock
├── models/child_model.dart       # Child, Observation, NCF-FS domains + multilingual keywords
├── providers/app_provider.dart   # all app state: roster, recording, drafts, consent, referrals
├── screens/                      # consent, home, profile, record, result, referral,
│                                 #   add_child, settings, app_shell (navigation)
├── services/
│   ├── classifier_service.dart   # domain tagger (TFLite-sim) + Jadui Pitara activity engine
│   ├── data_service.dart         # Hive persistence, seed data, crypto audit log (simulated)
│   └── translations.dart         # full UI strings: en / hi / ta / gu
└── widgets/                      # radar_chart, pitch_slides, crypto_sandbox
web/
├── speech_bridge.js              # Deepgram REST bridge + simulated-voice fallback
└── manifest.json                 # PWA manifest
```

## Run it

```bash
# web (dev)
flutter pub get
flutter run -d chrome

# web (production build — what Vercel deploys)
flutter build web --release

# android
flutter run -d <device>
```

Vercel deploys directly from this repo (`vercel.json`): it clones Flutter stable,
enables web, and builds `--release` into `build/web`.

## Privacy model (as demonstrated)

- Child identities are **pseudonymous** (`hmac_…` IDs); names never leave the device.
- The **crypto sandbox** shows the audit trail for every write: fields encrypted
  (AES-256-GCM, simulated), HMAC verification, and a DPDP status line —
  *"No cleartext PII leaves device"*.
- Referral exports are **header-pseudonymized** per the DPDP Act 2023.

> Prototype note: the crypto panel is a faithful *simulation* of the production
> crypto design — production must implement real AES-256-GCM/HMAC and key
> management. The domain classifier is keyword-based; production swaps in the
> <15 MB INT8 TFLite model.

## Roadmap

- [ ] Replace keyword classifier with the on-device TFLite INT8 model
- [ ] Real AES-256-GCM + HMAC key management (replace simulated crypto)
- [ ] Backend sync (outbox → server) with DPDP-grade audit logs
- [ ] Hindi/Tamil/Gujarati voice on native (Android) builds
- [ ] Longitudinal milestone charts and RBSK form integration

## License

MIT
