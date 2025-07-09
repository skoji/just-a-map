#!/bin/bash
#
# Finds the UDID of an available iOS simulator.
# Priority: iPhone Pro models > iPhone models > Any available iPhone

set -euo pipefail

# Find best available simulator UDID
pro_simulator_udid=$(xcrun simctl list devices available | grep 'iPhone' | grep 'Pro' | grep -o '[A-F0-9-]\{36\}' | head -n 1 || true)

if [ -n "$pro_simulator_udid" ]; then
    echo "$pro_simulator_udid"
    exit 0
fi

first_simulator_udid=$(xcrun simctl list devices available | grep 'iPhone' | grep -o '[A-F0-9-]\{36\}' | head -n 1 || true)

if [ -n "$first_simulator_udid" ]; then
    echo "$first_simulator_udid"
    exit 0
fi

# Fallback if no simulator is found by printing the UDID of the latest iPhone 15 Pro
fallback_udid=$(xcrun simctl list devices available | grep 'iPhone 15 Pro' | grep -o '[A-F0-9-]\{36\}' | head -n 1 || true)
if [ -n "$fallback_udid" ]; then
    echo "$fallback_udid"
    exit 0
fi

# If all else fails, exit with an error
>&2 echo "Error: No suitable iOS Simulator found."
exit 1