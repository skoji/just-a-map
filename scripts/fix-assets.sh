#!/usr/bin/env bash
set -euo pipefail

APP="xtool/JustAMap.app"
RESOURCE_ROOT="Resources/built"

cp -R "$RESOURCE_ROOT"/*.png "$RESOURCE_ROOT/Assets.car" "$APP/"
