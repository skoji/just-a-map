#!/usr/bin/env bash
set -euo pipefail

APP="xtool/JustAMap.app"
RESOURCE_ROOT="Resources/built"
VERSION_INFO="Resources/built/VersionInfo.plist"

cp -R "$RESOURCE_ROOT"/*.png "$RESOURCE_ROOT/Assets.car" "$APP/"

# Copy VersionInfo.plist if it exists
if [ -f "$VERSION_INFO" ]; then
    cp "$VERSION_INFO" "$APP/"
fi
