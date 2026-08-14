DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
PROJECT := MenuBarPiano.xcodeproj
SCHEME := MenuBarPiano
CONFIGURATION ?= Release
DERIVED_DATA := .build
APP := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/MenuBarPiano.app
APP_ABS := $(CURDIR)/$(APP)
BINARY := $(APP)/Contents/MacOS/MenuBarPiano
INSTALL_DIR ?= $(HOME)/Applications
INSTALLED_APP := $(INSTALL_DIR)/MenuBarPiano.app
INSTALLED_BINARY := $(INSTALLED_APP)/Contents/MacOS/MenuBarPiano
XCODEBUILD_SETTINGS ?=

RELEASE_VERSION ?= 1.0
BUILD_NUMBER ?= 1
SIGNING_IDENTITY ?= Developer ID Application
NOTARY_PROFILE ?= MenuBarPiano-notary
DIST_DIR ?= dist
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/MenuBarPiano.app
NOTARY_ARCHIVE := $(DERIVED_DATA)/MenuBarPiano-notarization.zip
RELEASE_ARCHIVE := $(DIST_DIR)/MenuBarPiano-$(RELEASE_VERSION).zip

.PHONY: build install run debug reveal release clean

build:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		$(XCODEBUILD_SETTINGS) build

install: build
	mkdir -p "$(INSTALL_DIR)"
	mkdir -p "$(INSTALLED_APP)"
	/usr/bin/rsync -aE --delete "$(APP_ABS)/" "$(INSTALLED_APP)/"
	codesign --verify --deep --strict "$(INSTALLED_APP)"
	@echo "Installed MenuBarPiano to $(INSTALLED_APP)"

run: install
	pkill -x MenuBarPiano 2>/dev/null || true
	@sleep 0.8
	@if ! open -n "$(INSTALLED_APP)"; then \
		echo "LaunchServices open failed; retrying once..."; \
		sleep 1; \
		open -n "$(INSTALLED_APP)"; \
	fi
	@sleep 1; \
	if pgrep -qx MenuBarPiano; then \
		echo "MenuBarPiano is running from $(INSTALLED_APP). The ♫ menu bar item should be visible."; \
	else \
		echo "Run 'make debug' to keep launch output attached."; \
		exit 1; \
	fi

debug: install
	pkill -x MenuBarPiano 2>/dev/null || true
	"$(INSTALLED_BINARY)"

reveal: install
	open -R "$(INSTALLED_APP)"

release:
	$(MAKE) clean
	mkdir -p "$(DIST_DIR)"
	rm -f "$(RELEASE_ARCHIVE)"
	$(MAKE) CONFIGURATION=Release \
		XCODEBUILD_SETTINGS='CODE_SIGNING_ALLOWED=NO ENABLE_HARDENED_RUNTIME=YES MARKETING_VERSION=$(RELEASE_VERSION) CURRENT_PROJECT_VERSION=$(BUILD_NUMBER)' \
		build
	/usr/bin/codesign --force --sign "$(SIGNING_IDENTITY)" \
		--options runtime --timestamp "$(RELEASE_APP)"
	/usr/bin/codesign --verify --deep --strict --verbose=2 "$(RELEASE_APP)"
	/usr/bin/codesign -d --verbose=4 "$(RELEASE_APP)" 2>&1
	@if /usr/bin/codesign -d --entitlements - "$(RELEASE_APP)" 2>/dev/null | /usr/bin/grep -q '<key>'; then \
		echo "Unexpected entitlements in release signature." >&2; \
		exit 1; \
	else \
		echo "Entitlements: none"; \
	fi
	rm -f "$(NOTARY_ARCHIVE)"
	/usr/bin/ditto -c -k --keepParent "$(RELEASE_APP)" "$(NOTARY_ARCHIVE)"
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun notarytool submit "$(NOTARY_ARCHIVE)" \
		--keychain-profile "$(NOTARY_PROFILE)" --wait
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun stapler staple -v "$(RELEASE_APP)"
	/usr/bin/ditto -c -k --keepParent "$(RELEASE_APP)" "$(RELEASE_ARCHIVE)"
	@echo "Verifying signed and notarized app..."
	/usr/bin/codesign --verify --deep --strict --verbose=2 "$(RELEASE_APP)"
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun stapler validate -v "$(RELEASE_APP)"
	/usr/sbin/spctl --assess --type execute --verbose=4 "$(RELEASE_APP)"
	@echo "Artifact: $(CURDIR)/$(RELEASE_ARCHIVE)"

clean:
	rm -rf "$(DERIVED_DATA)"
