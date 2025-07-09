#!/bin/bash

# Git-based version generation script
# Generates version information from Git repository state

set -euo pipefail

# Base semantic version (can be updated manually)
BASE_VERSION="1.0.0"

# Function to get Git commit count (build number)
get_build_number() {
    if git rev-list --count HEAD 2>/dev/null; then
        return 0
    else
        echo "1"
        return 1
    fi
}

# Function to get short commit hash
get_commit_hash() {
    if git rev-parse --short HEAD 2>/dev/null; then
        return 0
    else
        echo "unknown"
        return 1
    fi
}

# Function to check if working directory is clean
is_working_dir_clean() {
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Main version generation
generate_version_info() {
    local build_number
    local commit_hash
    local version_string
    
    # Get build number (Git commit count)
    build_number=$(get_build_number)
    
    # Get commit hash
    commit_hash=$(get_commit_hash)
    
    # Generate version string
    if is_working_dir_clean; then
        version_string="${BASE_VERSION}+${commit_hash}"
    else
        version_string="${BASE_VERSION}+${commit_hash}.dirty"
    fi
    
    # Output format based on argument
    case "${1:-}" in
        "build-number")
            echo "$build_number"
            ;;
        "version-string")
            echo "$version_string"
            ;;
        "commit-hash")
            echo "$commit_hash"
            ;;
        "json")
            cat <<EOF
{
  "buildNumber": "$build_number",
  "versionString": "$version_string",
  "commitHash": "$commit_hash",
  "baseVersion": "$BASE_VERSION"
}
EOF
            ;;
        *)
            echo "Usage: $0 [build-number|version-string|commit-hash|json]"
            echo "  build-number   - Output build number (Git commit count)"
            echo "  version-string - Output version string (semantic version + commit hash)"
            echo "  commit-hash    - Output commit hash"
            echo "  json          - Output all info as JSON"
            exit 1
            ;;
    esac
}

# Check if we're in a Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a Git repository" >&2
    exit 1
fi

# Generate version info
generate_version_info "$@"