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

.PHONY: build install run debug reveal clean

build:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		build

install: build
	mkdir -p "$(INSTALL_DIR)"
	ditto "$(APP_ABS)" "$(INSTALLED_APP)"
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
		echo "MenuBarPiano is running from $(INSTALLED_APP). The control panel should be visible."; \
	else \
		echo "Run 'make debug' to keep launch output attached."; \
		exit 1; \
	fi

debug: install
	pkill -x MenuBarPiano 2>/dev/null || true
	"$(INSTALLED_BINARY)"

reveal: install
	open -R "$(INSTALLED_APP)"

clean:
	rm -rf "$(DERIVED_DATA)"
