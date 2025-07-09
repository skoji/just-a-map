.PHONY: all build test clean install dev run check-assets compile-assets fix-assets help

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

# Device ID can be set via environment variable or command line
# Example: make install DEVICE_ID=00008140-000C7D8E362A801C
DEVICE_ID ?= 

# Build the app with xtool
build:
	@echo "Building app with xtool..."
	xtool dev build
	@$(MAKE) fix-assets

# Test the app
test:
	@echo "Running tests..."
	@if command -v xcodebuild >/dev/null 2>&1; then \
		if command -v xcpretty >/dev/null 2>&1; then \
			xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16' | xcpretty --test; \
		else \
			xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'; \
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

# Check if assets need to be recompiled
check-assets:
	@if [ ! -d "$(ASSETS_BUILT)" ]; then \
		echo "Compiled assets not found. Running compile-assets..."; \
		$(MAKE) compile-assets; \
	elif [ -n "$$(find $(ASSETS_SOURCE) -newer $(ASSETS_BUILT)/Assets.car 2>/dev/null)" ]; then \
		echo "Source assets have been updated. Recompiling..."; \
		$(MAKE) compile-assets; \
	else \
		echo "Assets are up to date."; \
	fi

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

# Build and run in simulator
run: build
	@echo "Running in simulator..."
	xtool dev run --simulator

# List available devices
devices:
	@echo "Available devices:"
	@xtool devices

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
	@echo "  make run           - Build and run in simulator"
	@echo "  make check-assets  - Check if assets need recompilation"
	@echo "  make compile-assets - Compile assets (macOS only)"
	@echo "  make fix-assets    - Fix assets in app bundle"
	@echo "  make devices       - List available devices"
	@echo "  make lint          - Run SwiftLint"
	@echo "  make format        - Format Swift code"
	@echo "  make help          - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make install DEVICE_ID=00008140-000C7D8E362A801C"
	@echo "  make test"