# Why Verto is built the way it is

Decisions taken while building the app, with the alternatives that were rejected and
why. If something here looks like it could be simplified, the reason it was not is
probably below.

Dates are when the decision was taken, not when the code landed.

## Translation

**The engine is Apple's on-device `Translation.framework`** (2026-09-08). Free,
offline, no API key, and the language packs are shared with the rest of the system, so
the app ships at under a megabyte. *Rejected:* DeepL, whose quality is better but which
needs a key from every user and a network; and Google's unofficial web endpoint, which
is exactly what killed MATE, the app this one replaces.

**The direct session API, not the SwiftUI `.translationTask` modifier** (2026-09-08).
`TranslationSession(installedSource:target:)` and `cancel()` exist from macOS 26, which
keeps translation out of the view layer and makes cancellation the framework's own
rather than a race between tasks. The cost is the macOS 26 minimum. The modifier
survives in one place only: downloading a language pack, which has no programmatic API.

**`cancel()` ends a session for good.** It is not "cancel the current request" — a
cancelled session refuses every later one. Caching a session and cancelling it per
keystroke poisoned the cache after the first translation. Sessions are now discarded
after a cancel and after any failure.

**Debounce is 300 ms,** long enough that typing does not fire a request per character,
short enough to feel instant on paste.

## Detecting the direction

**The method is chosen from the pair, not fixed** (2026-09-08). When the two languages
use different writing systems, counting characters beats a language model: it is exact
on short strings like "OK" or "Pizza", where `NLLanguageRecognizer` answers with
confident nonsense. Pairs that share a writing system (EN/DE, RU/UK) fall back to the
model and say when they are unsure.

An earlier version asked "is there Cyrillic?", which would have been wrong 100% of the
time on RU↔UK. A language can also use several scripts at once — Japanese uses kana and
kanji together — so each language carries a *set* of scripts and a pair is countable
when those sets are disjoint.

**The threshold is 15%, not 50%.** Real writing is mixed: *"задеплой на staging через
CI"* is a Russian sentence with three English words in it. Only letters belonging to one
of the two chosen languages get a vote; everything else carries no evidence.

The first test of this threshold proved nothing — its phrase was 62% Cyrillic, so it
passed at every threshold up to 62. Boundary tests now state their share and straddle
the line.

## Interface

**Menu bar only, no Dock icon.** Clicking a Dock icon should open something, and a
popover under the menu bar is not that. The cost is that everything a window gives you
for free has to be built by hand: the main menu (without it `⌘V` does nothing at all),
a way to quit, bringing the settings window forward.

**A Dock icon appears while the settings window is open** (2026-09-08) and goes away
with it. The activation policy has to change *before* the window is ordered in, and back
one run-loop turn *after* it closes, or the icon is stranded.

**The window opens empty every time** (2026-09-08). Reopening with the last phrase still
in it meant clearing the field before pasting — a chore in the one place this app
promises there are none. Safe only because closing files the translation in the history.

**Re-translating the same text moves its history entry up** rather than adding a copy,
or closing and reopening on one phrase would bury everything else under duplicates.

**The direction indicator is a button.** Detection will be wrong eventually; the user
should see the decision before reading a wrong translation, and fix it in one click.

**A label in the interface is a promise.** The footer advertised `⌘↩`, `⌘S` and `esc`
for a while before any of them existed. Do not draw a control before it works.

## Localisation

**English base, Russian alongside, following the system** with an explicit override in
settings (2026-09-08). Switching applies immediately: strings are read from a bundle the
app points at, rather than through `AppleLanguages`, which only takes effect on relaunch.

Two things kept speaking the system's language after that and had to be fixed
separately: language names, which came from `Locale.current`, and the settings window
title, which AppKit does not redraw. Both were invisible in the source and obvious in a
screenshot.

## Screen capture

**`screencapture -i`, not ScreenCaptureKit** (2026-09-08). The system tool already
provides the selection people know — crosshair, space to move it, escape to cancel.

**Vision names its languages with a region attached** (`ar-SA`, `vi-VT`, `zh-TW`), so
matching whole identifiers against `ar` matched nothing and left the request with an
empty language list, which makes it read everything as English. Matching is on language
code. Of the 19 languages Verto translates, Vision cannot read Hindi.

**Recognised text goes into the editable field, not straight through.** OCR confuses
short uppercase runs — `CI` comes out as `Cl`, on both language-correction settings —
and the user has to see that before taking the translation.

## Distribution

**Ad-hoc signature, no paid certificate** (2026-09-08). The install instructions are
four steps ending in *System Settings → Privacy & Security → Open Anyway*; the terminal
one-liner is an alternative, not the path. *Rejected for now:* a Homebrew cask, which
would remove the friction for free, and the $99 certificate, which would remove it for
everyone.

**A zip, not a disk image.** A quarantined `.dmg` refuses to mount and macOS calls it
*damaged*, which reads as a corrupt download and sends people away. A quarantined zip
extracts, and the warning arrives at launch where it can be answered.

**A DMG only when a catalog requires one** (2026-11-17). The appstorrent submission
needs a `.dmg` link, so `make dmg` produces an ad-hoc image as an optional asset. The zip
remains the recommended download for an unsigned build: the DMG can still be refused by
Gatekeeper when quarantined.

**Local builds use a self-signed identity, releases do not.** See `AGENTS.md`.

## Tooling

**No asset catalogue.** The icon is drawn by `Tools/make-icon.swift` and packed with
`iconutil`, which removes a dependency on `actool` and a whole class of build problems.

Two bugs in that icon were found by looking at the rendered file, not the code: a
gradient that ended at the edge of its own rectangle drew a hard line across the glyph,
and in a flipped context `angle: -90` lit the icon from below, which macOS icons never
are.

**The language detector lives in `VertoCore`,** a library with no UI, so its rules can
be tested. Everything in `Sources/Verto` is interface and system integration.
