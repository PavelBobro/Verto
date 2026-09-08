# Builds Verto.app without Xcode: SwiftPM compiles the binaries, this assembles the
# bundle around them. `make run` to build and launch, `make app` for the bundle alone.
#
# Build with the Command Line Tools toolchain even when Xcode is installed: a freshly
# installed Xcode blocks every build until its licence is accepted, and Verto needs
# no part of Xcode.
export DEVELOPER_DIR ?= /Library/Developer/CommandLineTools

VERSION   := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
APP       := Verto
BUNDLE    := $(APP).app
CONTENTS  := $(BUNDLE)/Contents
CONFIG    ?= release
DEPLOY    := macosx26.0
DMG       := $(APP)-$(VERSION).dmg

# Each architecture is built on its own and the results are joined with lipo.
# `swift build --arch a --arch b` would produce a universal binary in one pass, but it
# needs xcbuild, which ships only with Xcode.
ARM_TRIPLE := arm64-apple-$(DEPLOY)
X86_TRIPLE := x86_64-apple-$(DEPLOY)

.PHONY: all app run install test strings clean sign check icon dmg zip release

all: app

## Compile both architectures, assemble Verto.app, sign it ad-hoc.
app: icon
	swift build -c $(CONFIG) --triple $(ARM_TRIPLE)
	swift build -c $(CONFIG) --triple $(X86_TRIPLE)
	rm -rf $(BUNDLE)
	mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	lipo -create \
	  "$$(swift build -c $(CONFIG) --triple $(ARM_TRIPLE) --show-bin-path)/$(APP)" \
	  "$$(swift build -c $(CONFIG) --triple $(X86_TRIPLE) --show-bin-path)/$(APP)" \
	  -output $(CONTENTS)/MacOS/$(APP)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/$(APP).icns $(CONTENTS)/Resources/
	cp -R Resources/*.lproj $(CONTENTS)/Resources/
	printf 'APPL????' > $(CONTENTS)/PkgInfo
	$(MAKE) sign
	@echo "built $(BUNDLE) — $$(lipo -archs $(CONTENTS)/MacOS/$(APP))"

## Every key used in code has a translation in every language, and no more.
strings:
	./Tools/check-strings.sh

## Run the tests. Unlike the build, these need Xcode: swift-testing ships with it
## and not with the Command Line Tools.
test: strings
	DEVELOPER_DIR= swift test

## Zip the app for release. Preferred over the disk image while Verto is unsigned:
## a quarantined .dmg refuses to mount at all and macOS calls it "damaged", which
## reads as a corrupt download. A quarantined .zip extracts fine and the warning
## arrives at launch instead, where it can be answered.
zip: app
	rm -f $(APP)-$(VERSION).zip
	ditto -c -k --keepParent $(BUNDLE) $(APP)-$(VERSION).zip
	@echo "$(APP)-$(VERSION).zip — $$(du -h $(APP)-$(VERSION).zip | cut -f1)"

## What goes on a release page. Only the zip while Verto is unsigned: a quarantined
## disk image will not mount at all, and System Settings offers nothing to click for
## it — the zip's refusal can at least be answered with "Open Anyway".
release: zip

## Package Verto.app into a disk image for release.
## hdiutil is part of macOS, so this needs no developer tooling either.
dmg: app
	rm -rf .dmg $(DMG)
	mkdir -p .dmg
	cp -R $(BUNDLE) .dmg/
	ln -s /Applications .dmg/Applications
	hdiutil create -volname "$(APP) $(VERSION)" -srcfolder .dmg -ov -format UDZO $(DMG)
	rm -rf .dmg
	@echo "$(DMG) — $$(du -h $(DMG) | cut -f1)"

## Redraw the app icon from source. No asset catalogue, no Xcode.
icon:
	swift Tools/make-icon.swift Resources
	iconutil -c icns Resources/$(APP).iconset -o Resources/$(APP).icns

## Sign with the local identity when there is one, ad-hoc otherwise.
##
## An ad-hoc signature has no identity, so macOS recognises the app by a hash of its
## contents: change a line of code and every permission granted — screen recording,
## login item — belongs to what the system now treats as a different app, and it asks
## again. A stable identity ends that. Tools/make-signing-identity.sh creates one.
##
## Not --deep: Apple advises against it, and a single-binary bundle has nothing
## nested to sign anyway.
IDENTITY := $(shell security find-identity -v -p codesigning 2>/dev/null \
              | grep -o '"Verto Local Signing"' | head -1 | tr -d '"')

sign:
ifeq ($(IDENTITY),)
	@echo "подписываю одноразово (Tools/make-signing-identity.sh даст постоянную подпись)"
	codesign --force --options runtime -s - $(BUNDLE)
else
	codesign --force --options runtime -s "$(IDENTITY)" $(BUNDLE)
endif

## Build and launch straight away.
run: app
	open $(BUNDLE)

## Replace the copy in /Applications and restart it.
##
## Two bundles with the same identifier confuse macOS about which one to launch, and
## permissions granted to one look like they were ignored by the other. There should
## be exactly one installed copy, and this is how it gets replaced.
install: app
	@pkill -f "/Applications/$(BUNDLE)/Contents/MacOS/$(APP)" 2>/dev/null || true
	@sleep 1
	rm -rf /Applications/$(BUNDLE)
	cp -R $(BUNDLE) /Applications/
	open /Applications/$(BUNDLE)
	@echo "installed and running from /Applications"


## Verify the bundle is well-formed, universal, and correctly signed.
check: strings
	plutil -lint $(CONTENTS)/Info.plist
	lipo -archs $(CONTENTS)/MacOS/$(APP)
	codesign --verify --verbose=2 $(BUNDLE)

clean:
	rm -rf .build $(BUNDLE) .dmg *.dmg *.zip Resources/$(APP).iconset Resources/$(APP).icns
