#!/bin/bash
#
# Finds the UDID of the most appropriate available iOS simulator.
# It prioritizes simulators matching the host architecture (arm64 vs x86_64)
# and prefers Pro models over regular ones.

set -euo pipefail

# Determine host architecture
HOST_ARCH=$(uname -m)

# First try using xcrun simctl to find available simulators
# This is more reliable in CI environments
find_simulator_with_simctl() {
    # Get available simulators
    local simulators=$(xcrun simctl list devices available 2>/dev/null | grep -E "iPhone.*\(" | grep -v "unavailable" || true)
    
    if [ -z "$simulators" ]; then
        return 1
    fi
    
    # Extract simulator info - format is like: iPhone 15 Pro (UUID) (Shutdown)
    # Priority 1: iPhone Pro models
    local udid=$(echo "$simulators" | grep "Pro" | sed -n 's/.*(\([A-F0-9-]*\)).*/\1/p' | head -n 1 || true)
    if [ -n "$udid" ]; then
        echo "$udid"
        return 0
    fi
    
    # Priority 2: Any iPhone
    udid=$(echo "$simulators" | sed -n 's/.*(\([A-F0-9-]*\)).*/\1/p' | head -n 1 || true)
    if [ -n "$udid" ]; then
        echo "$udid"
        return 0
    fi
    
    return 1
}

# Fallback to xcodebuild -showdestinations
find_simulator_with_xcodebuild() {
    # Get all available iOS Simulator destinations from xcodebuild
    # The output format is like: { platform:iOS Simulator, arch:arm64, id:UDID, OS:17.0.1, name:iPhone 15 Pro }
    local destinations=$(xcodebuild -showdestinations -scheme JustAMap 2>/dev/null | grep "platform:iOS Simulator" || true)
    
    if [ -z "$destinations" ]; then
        return 1
    fi
    
    # 1. iPhone Pro matching host architecture
    local udid=$(echo "$destinations" | grep "name:iPhone" | grep "Pro" | grep "arch:$HOST_ARCH" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
    if [ -n "$udid" ]; then
        echo "$udid"
        return 0
    fi
    
    # 2. Any iPhone matching host architecture
    udid=$(echo "$destinations" | grep "name:iPhone" | grep "arch:$HOST_ARCH" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
    if [ -n "$udid" ]; then
        echo "$udid"
        return 0
    fi
    
    # 3. (Fallback) iPhone Pro with any architecture
    udid=$(echo "$destinations" | grep "name:iPhone" | grep "Pro" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
    if [ -n "$udid" ]; then
        echo "$udid"
        return 0
    fi
    
    # 4. (Fallback) Any iPhone with any architecture
    udid=$(echo "$destinations" | grep "name:iPhone" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p' | head -n 1 || true)
    if [ -n "$udid" ]; then
        echo "$udid"
        return 0
    fi
    
    return 1
}

# Try simctl first, then xcodebuild
if UDID=$(find_simulator_with_simctl); then
    echo "$UDID"
    exit 0
fi

if UDID=$(find_simulator_with_xcodebuild); then
    echo "$UDID"
    exit 0
fi

# If all else fails, exit with an error
>&2 echo "Error: No suitable iOS Simulator found."
>&2 echo "Available simulators:"
>&2 xcrun simctl list devices available | grep -E "iPhone.*\(" || true
exit 1
