#!/bin/bash
#
# Finds the UDID of the most appropriate available iOS simulator.
# It prioritizes simulators matching the host architecture (arm64 vs x86_64)
# and prefers Pro models over regular ones.

set -euo pipefail

# Determine host architecture
HOST_ARCH=$(uname -m)

# Get all available iOS Simulator destinations from xcodebuild
# The output format is like: { platform:iOS Simulator, arch:arm64, id:UDID, OS:17.0.1, name:iPhone 15 Pro }
DESTINATIONS=$(xcodebuild -showdestinations -scheme JustAMap 2>/dev/null | grep "platform:iOS Simulator")

# --- Find the best possible UDID --- 

# 1. iPhone Pro matching host architecture
UDID=$(echo "$DESTINATIONS" | grep "name:iPhone" | grep "Pro" | grep "arch:$HOST_ARCH" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
if [ -n "$UDID" ]; then
    echo "$UDID"
    exit 0
fi

# 2. Any iPhone matching host architecture
UDID=$(echo "$DESTINATIONS" | grep "name:iPhone" | grep "arch:$HOST_ARCH" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
if [ -n "$UDID" ]; then
    echo "$UDID"
    exit 0
fi

# 3. (Fallback) iPhone Pro with any architecture
UDID=$(echo "$DESTINATIONS" | grep "name:iPhone" | grep "Pro" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
if [ -n "$UDID" ]; then
    echo "$UDID"
    exit 0
fi

# 4. (Fallback) Any iPhone with any architecture
UDID=$(echo "$DESTINATIONS" | grep "name:iPhone" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
if [ -n "$UDID" ]; then
    echo "$UDID"
    exit 0
fi

# If all else fails, exit with an error
>&2 echo "Error: No suitable iOS Simulator found."
exit 1
