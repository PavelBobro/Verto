# Builds Verto.app without Xcode: SwiftPM compiles the binaries, this assembles the
# bundle around them. `make run` to build and launch, `make app` for the bundle alone.
#
# Build with the Command Line Tools toolchain even when Xcode is installed: a freshly
# installed Xcode blocks every build until its licence is accepted, and Verto needs
# no part of Xcode.
export DEVELOPER_DIR ?= /Library/Developer/CommandLineTools

APP       := Verto
BUNDLE    := $(APP).app
CONTENTS  := $(BUNDLE)/Contents
CONFIG    ?= release
DEPLOY    := macosx26.0

# Each architecture is built on its own and the results are joined with lipo.
# `swift build --arch a --arch b` would produce a universal binary in one pass, but it
# needs xcbuild, which ships only with Xcode.
ARM_TRIPLE := arm64-apple-$(DEPLOY)
X86_TRIPLE := x86_64-apple-$(DEPLOY)

.PHONY: all app run clean sign check icon

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
	printf 'APPL????' > $(CONTENTS)/PkgInfo
	$(MAKE) sign
	@echo "built $(BUNDLE) — $$(lipo -archs $(CONTENTS)/MacOS/$(APP))"

## Redraw the app icon from source. No asset catalogue, no Xcode.
icon:
	swift Tools/make-icon.swift Resources
	iconutil -c icns Resources/$(APP).iconset -o Resources/$(APP).icns

## Ad-hoc signature. Not --deep: Apple advises against it, and a single-binary
## bundle has nothing nested to sign anyway.
sign:
	codesign --force --options runtime -s - $(BUNDLE)

## Build and launch straight away.
run: app
	open $(BUNDLE)

## Verify the bundle is well-formed, universal, and correctly signed.
check:
	plutil -lint $(CONTENTS)/Info.plist
	lipo -archs $(CONTENTS)/MacOS/$(APP)
	codesign --verify --verbose=2 $(BUNDLE)

clean:
	rm -rf .build $(BUNDLE) Resources/$(APP).iconset Resources/$(APP).icns
