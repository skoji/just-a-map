.PHONY: all build test clean distclean install dev install-to-simulator run check-assets compile-assets fix-assets devices lint format help

# Default target
all: build

# Check if we're on macOS (for actool)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    HAS_ACTOOL := $(shell command -v actool 2> /dev/null)
endif

# Paths
ASSETS_SOURCE := Resources/source/Assets.xcassets
ASSETS_BUILT := Resources/built
APP_BUNDLE := xtool/JustAMap.app

# Asset source files for dependency tracking
ASSET_SOURCES := $(shell find $(ASSETS_SOURCE) -type f 2>/dev/null)

# Device ID can be set via environment variable or command line
# Example: make install DEVICE_ID=00008140-000C7D8E362A801C
DEVICE_ID ?= 

# Host architecture for simulator selection
HOST_ARCH := $(shell uname -m)

# Dynamically select an available iOS simulator for testing
# This is done via a helper script to avoid complex Makefile escaping.
SIMULATOR_ID := $(shell ./scripts/find-simulator.sh)

# Build the app with xtool
build:
	@echo "Building app with xtool..."
	@$(MAKE) sync-version-info
	xtool dev build
	@$(MAKE) fix-assets

# Test the app
test:
	@echo "Running tests..."
	@$(MAKE) sync-version-info
	@echo "Selected simulator ID: $(SIMULATOR_ID) (arch: $(HOST_ARCH))"
	@if command -v xcodebuild >/dev/null 2>&1; then \
		if command -v xcpretty >/dev/null 2>&1; then \
			set -o pipefail && xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,id=$(SIMULATOR_ID),arch=$(HOST_ARCH)' | xcpretty --test; \
		else \
			xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,id=$(SIMULATOR_ID),arch=$(HOST_ARCH)'; \
		fi \
	else \
		echo "Error: xcodebuild not found. Tests can only be run on macOS with Xcode installed."; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf .build
	rm -rf xtool
	swift package clean

# Clean everything including compiled assets
distclean: clean
	@echo "Cleaning everything including compiled assets..."
	rm -rf $(ASSETS_BUILT)

# Assets.car dependency rule - compiles when source files change
$(ASSETS_BUILT)/Assets.car: $(ASSET_SOURCES)
ifdef HAS_ACTOOL
	@echo "Compiling assets..."
	@./scripts/compile-assets.sh
else
	@echo "Warning: actool is not available (not on macOS)."
	@echo "Assets compilation requires macOS. Please compile on macOS when changing assets."
	@if [ ! -f "$@" ]; then \
		echo "Error: No compiled assets found and cannot compile on this platform."; \
		exit 1; \
	fi
endif

# Check if assets need to be recompiled
check-assets: $(ASSETS_BUILT)/Assets.car
	@echo "Assets are up to date."

# Compile assets (macOS only)
compile-assets:
ifdef HAS_ACTOOL
	@echo "Compiling assets..."
	@./scripts/compile-assets.sh
else
	@echo "Warning: actool is not available (not on macOS)."
	@echo "Assets compilation requires macOS. Please compile on macOS when changing assets."
	@if [ ! -d "$(ASSETS_BUILT)" ]; then \
		echo "Error: No compiled assets found and cannot compile on this platform."; \
		exit 1; \
	fi
endif

# Fix assets in app bundle
fix-assets:
	@if [ -d "$(APP_BUNDLE)" ]; then \
		echo "Fixing assets in app bundle..."; \
		./scripts/fix-assets.sh; \
	else \
		echo "Error: App bundle not found at $(APP_BUNDLE)"; \
		echo "Run 'make build' first."; \
		exit 1; \
	fi

# Sync version info from Git
sync-version-info:
	@echo "Syncing version info from Git..."
	@./scripts/sync-version-info.sh

# Show current version info
show-version:
	@echo "Current Git-based version information:"
	@echo "  Version: $$(./scripts/generate-version.sh version-string)"
	@echo "  Build Number: $$(./scripts/generate-version.sh build-number)"
	@echo "  Commit Hash: $$(./scripts/generate-version.sh commit-hash)"

# Install to device
install: build
	@if [ -z "$(DEVICE_ID)" ]; then \
		echo "Error: DEVICE_ID is not set."; \
		echo "Usage: make install DEVICE_ID=<your-device-id>"; \
		echo ""; \
		echo "To find your device ID, run: xtool devices"; \
		exit 1; \
	fi
	@echo "Installing to device $(DEVICE_ID)..."
	xtool install -u $(DEVICE_ID) $(APP_BUNDLE)

# Development mode - build and watch for changes
dev: check-assets
	@echo "Starting development mode..."
	@echo "Note: After making changes, you may need to run 'make fix-assets' manually"
	xtool dev

# Build and install in simulator
install-to-simulator: build
	@echo "Installing in simulator..."
	xtool dev run --simulator

# Run the app in simulator
run: install-to-simulator
	@echo "Running app in simulator..."
	xcrun simctl launch --console-pty booted jp.skoji.JustAMap

# List available devices
devices:
	@echo "Available devices:"
	@xtool devices

# Show selected simulator for testing
show-simulator:
	@echo "Selected simulator for testing: $(SIMULATOR_ID)"
	@echo ""
	@echo "Available iOS simulators:"
	@xcrun simctl list devices available | grep "iPhone"

# Lint Swift code
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "Running SwiftLint..."; \
		swiftlint; \
	else \
		echo "SwiftLint is not installed. Install it with: brew install swiftlint"; \
	fi

# Format Swift code
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "Formatting Swift code..."; \
		swift-format -i -r Sources/ Tests/; \
	else \
		echo "swift-format is not installed."; \
		echo "Install it from: https://github.com/apple/swift-format"; \
	fi

# Help
help:
	@echo "Available targets:"
	@echo "  make build         - Build the app"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make distclean     - Clean everything including compiled assets"
	@echo "  make install       - Install to device (requires DEVICE_ID)"
	@echo "  make dev           - Start development mode"
	@echo "  make run           - Build and run in simulator; console-pty enabled"
	@echo "  make check-assets  - Check if assets need recompilation"
	@echo "  make compile-assets - Compile assets (macOS only)"
	@echo "  make fix-assets    - Fix assets in app bundle"
	@echo "  make sync-version-info - Sync version info from Git to VersionInfo.plist"
	@echo "  make show-version  - Show current Git-based version information"
	@echo "  make devices       - List available devices"
	@echo "  make show-simulator - Show selected simulator for testing"
	@echo "  make lint          - Run SwiftLint"
	@echo "  make format        - Format Swift code"
	@echo "  make help          - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make install DEVICE_ID=00008140-000C7D8E362A801C"
	@echo "  make test"
