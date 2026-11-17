# Verto — specification

This file is the entry point. The original v1 scope document is historical and lives
at [docs/SPEC-v1-archive.md](docs/SPEC-v1-archive.md); it is kept for the reasoning and
the rejected alternatives, not as a description of the current build.

Current documents:

- [README.md](README.md) — what the app is, how to install and use it.
- [docs/DECISIONS.md](docs/DECISIONS.md) — why the code is shaped this way.
- [AGENTS.md](AGENTS.md) — build, release and verification commands.
- [docs/SPEC-v1-archive.md](docs/SPEC-v1-archive.md) — the v1 plan, archived.

## Product rule

There is no direction-of-translation setting. The user picks a pair of languages;
Verto reads each input and decides which way to translate it.

## Current state

As of 2026-11-17:

- macOS 26 or later, Apple Silicon and Intel.
- Apple's on-device `Translation.framework`, offline after the language packs are
  installed.
- Menu bar only; no Dock icon except while Settings is open.
- Screen-area OCR through `screencapture -i` and Vision; recognised text lands in the
  editable field before translation.
- History of up to 50 translations, versioned on disk.
- Interface in English and Russian, following the system or chosen in Settings.
- Release artifact is `Verto-x.y.z.zip`, ad-hoc signed.
- `VertoCore` holds language detection, history and hotkey rules; `VertoAppModel`
  holds the popover model and translation wrapper; `Verto` is the AppKit/SwiftUI app.
- Tests: `make test` (core, model and translation-service rules); CI runs tests and a
  universal build on macOS 26.
