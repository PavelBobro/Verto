# Verto

A menu bar translator for macOS that never asks which way to translate.

Pick a language pair once. Paste Russian, get English. Paste English, get Russian.
Same window, no switch to flip, nothing to click.

*Verto* is Latin for "I turn; I translate" — both halves of what it does.

---

## Why

Every translator app makes you set a direction, and then punishes you for pasting
text that goes the other way. You lose a few seconds, every other time you use it.
Verto has no direction setting at all: it reads the text and decides.

- **Offline and free.** Uses Apple's on-device `Translation.framework`.
  No API keys, no accounts, no network, no telemetry.
- **Instant.** Translation starts 300 ms after you stop typing. Nothing to press.
- **Native.** Liquid Glass, SF Pro, standard controls. It looks like it shipped
  with the system.

## Requirements

macOS 26 or later. Apple Silicon or Intel.

## Install

1. Download the `.zip` from [the latest release](https://github.com/PavelBobro/Verto/releases/latest)
   and unzip it.
2. Drag **Verto** to your Applications folder.
3. Open it. macOS will refuse, because Verto is not signed with a paid Apple
   Developer certificate.
4. Open **System Settings → Privacy & Security**, scroll to the bottom, and click
   **Open Anyway** next to the message about Verto. Once. Then launch it again.

That fourth step is macOS asking whether you trust software that did not come
through the App Store. There is no way around it for an unsigned app, and anyone who
tells you to disable Gatekeeper entirely is giving you bad advice.

If you prefer the terminal, this does the same thing in one line:

```bash
xattr -dr com.apple.quarantine /Applications/Verto.app
```

### Or build it yourself

One command, no Xcode, and nothing to approve — a build you made carries no
quarantine flag:

```bash
git clone https://github.com/PavelBobro/Verto.git && cd Verto && make run
```

Command Line Tools are enough (`xcode-select --install` if you have neither).
`make` compiles both architectures, draws the icon, assembles `Verto.app` and signs
it ad-hoc.

Verto is around 1 MB. The translation engine and the language packs belong to macOS
and are shared with every other app that uses it, so none of that ships here.

## Use

| | |
|---|---|
| `⌥⌘T` | Open the popover from anywhere (rebindable in Settings) |
| `⌘↩` | Copy the translation and close |
| `⌘S` | Flip the direction, if detection got it wrong |
| `esc` | Close |

The viewfinder in the header translates text on screen: it hands you the same
crosshair as `⌘⇧4`, reads the text out of whatever you select, and translates it.
macOS asks for screen recording permission the first time, and the app has to be
restarted once after you grant it.

The window opens empty every time. Closing it files the translation in the history —
the clock in the header — so clearing the field costs you nothing.

`↩` inserts a line break — translation happens on its own, so Enter is free.

Settings live behind the gear in the popover, `⌘,`, or a right-click on the menu bar
icon. Verto has no Dock icon — it lives in the menu bar — except while the settings
window is open, when it behaves like an ordinary app and then drops back.

## Languages

Any two of the 19 languages Apple translates on device: Arabic, Chinese, Dutch,
English, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish,
Portuguese, Russian, Spanish, Thai, Turkish, Ukrainian, Vietnamese.

Language packs download once per pair, from Settings, and translation is offline
afterwards. Packs are directional, so Verto fetches both ways for you.

## How direction detection works

When the two languages use different writing systems (RU↔EN, JA↔EN, AR↔FR), Verto
counts characters instead of running a language model. Models are unreliable on short
strings — ask one about "OK" or "Pizza" — and counting is exact and instant.

Only letters belonging to one of the two chosen languages get a vote. The threshold is
15% rather than 50%, because real writing is mixed: *"задеплой на staging через CI"*
is a Russian sentence with three English words in it. A language may use several
scripts at once — Japanese uses kana and kanji together — and all of them count.

When the two share a writing system (EN↔DE, RU↔UK), Verto falls back to
`NLLanguageRecognizer` and warns you when it is unsure.

## Tests

```bash
make test         # localisation check, then swift test
```

Unlike the build, the tests need Xcode — swift-testing ships with it and not with the
Command Line Tools.

They cover the detector: the threshold cases either side of 15%, each stating its
share of the second alphabet; the short strings a language model gets wrong; Japanese
written in kana and kanji at once; and the pairs that share a writing system and
therefore cannot be counted at all.

## Languages of the interface

English and Russian. The app follows the system by default, and Settings can pin it
to either — useful if you run macOS in one language and would rather read Verto in
another. The change applies immediately, with no restart. Adding another is a file: copy
`Resources/en.lproj/Localizable.strings` to a folder named after the language code — `de.lproj`, say, translate the right-hand
side, add the code to `CFBundleLocalizations` in `Resources/Info.plist`.
`make strings` then checks that every key in the code has a translation and that no
translation is left unused.

## Not there yet

No signed release, so macOS asks you to approve the app once.

Recognised text is put in the editable field rather than translated blind: OCR
confuses short uppercase runs — `CI` comes out as `Cl` — and you should see that
before you take the translation.

## Roadmap

Search in history · faster switching between language pairs.

## License

MIT
