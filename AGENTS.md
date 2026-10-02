# Working on Verto

A menu bar translator for macOS. Written with Claude Code; this file is here so any
assistant — Codex, or a person — can pick the work up without the conversation that
produced it.

Read `docs/DECISIONS.md` before changing behaviour: most of what looks odd here was
chosen on purpose, and the reasons are written down.

## The one rule

**There is no direction-of-translation setting, and there must never be one.** The
user picks a pair of languages; Verto reads each input and decides which way to
translate it. Every other feature is negotiable; this one is the product.

## Commands

```bash
make app        # build Verto.app into build.noindex/
make install    # build, replace /Applications/Verto.app, relaunch
make run        # build and launch from build.noindex/
make test       # localisation check, then the test suite
make release    # the zip that goes on a GitHub release
make check      # bundle is well formed, universal, correctly signed
make icon       # redraw Verto.icns from Tools/make-icon.swift
```

Xcode is **not** required and should not become required: Command Line Tools are
enough for building and for tests. `make` pins `DEVELOPER_DIR` to them.

## Toolchain traps (all hit in practice)

- **`@State` does not compile without Xcode** from the macOS 27 SDK on — it became a
  macro whose implementation ships only with Xcode. Keep view state in an
  `ObservableObject` instead. `@StateObject`, `@ObservedObject`, `@Published` and
  `@FocusState` are unaffected.
- **swift-testing's macro plugin** lives in `plugins/testing/`, which the build system
  does not search; the Makefile passes `-plugin-path` when that folder exists.
- **Both architectures build into one folder** from Swift 6.4, so each triple gets its
  own `--scratch-path`. Without that, `lipo` is handed one file twice and the build
  dies halfway, leaving an empty bundle while reporting success.
- **Build products go in `build.noindex/`** so Spotlight and Launchpad do not show a
  second "Verto" beside the installed one.

## Conventions

- **No user-visible string literals in code.** Keys live in `Sources/Verto/Localized.swift`,
  text in `Resources/{en,ru}.lproj/Localizable.strings`. `make strings` fails if a key
  has no translation or a translation has no key. Anything the system localises for us
  (language names, dates) goes through `L.locale`, not `Locale.current`.
- **The model drives translation, not the view.** Text arriving while a field is off
  screen — recognised from a screenshot, say — must still translate. Nothing the app
  *does* may depend on what is drawn.
- **Anything long-lived must be told about changes.** This app has no windows that come
  and go: the popover, the menus and the settings window are built once and live for
  the session. SwiftUI redraws itself; AppKit titles and menus do not.
- **Never write to `state` from a superseded request.** Each request carries a
  generation; only the latest one is allowed to land.
- **Comments say why, not what.** Assume the reader can read Swift.

## Signing

- Local builds are signed with a self-signed identity (`Tools/make-signing-identity.sh`)
  so macOS keeps treating rebuilds as the same app and permissions survive. Without it,
  an ad-hoc signature changes with every code change and the screen-recording prompt
  comes back forever.
- **Release builds are ad-hoc on purpose** (`make zip` forces it). That certificate is
  trusted on one machine only; shipping it would hand strangers a signature from an
  authority they have no reason to accept.

## Diagnostics

An app with no window is hard to interrogate, so it can answer for itself:

```bash
/Applications/Verto.app/Contents/MacOS/Verto --probe-locale        # language resolution
/Applications/Verto.app/Contents/MacOS/Verto --probe-login-item    # login item, then undoes it
log show --last 30m --predicate 'subsystem == "app.verto.Verto"' --style compact
```

Use them before theorising. Two bugs here looked impossible in the source and took one
probe each to explain.

## Verifying

Check the result, not the report. A `make install` once exited 0 while leaving the old
app in place; only the file's timestamp showed it. Before claiming a release is good,
unpack the zip and look inside it rather than at the folder it was made from.

Screenshots are part of testing. Two localisation bugs survived code review and were
caught the first time someone photographed the window.

## Releasing

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. `make test && make release`
3. Unpack `Verto-x.y.z.zip` and check version, architectures, signature, localisations.
4. `gh release create vX.Y.Z Verto-X.Y.Z.zip --title "Verto X.Y.Z" --notes ...`
5. `make install` to put the locally-signed build back on this machine.

Say what is actually known in release notes. If a fix is "two ways it could get stuck"
rather than a proven root cause, write that.

## Deliberately not doing

The owner builds this for himself, and rejected these on that basis: translating the
selected text in another app (would need Accessibility), text-to-speech, an optional
DeepL engine, and a paid Apple Developer certificate. Do not add them back as
"improvements".
