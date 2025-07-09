#!/bin/bash

# Update version info in Info.plist with Git-based versioning
# This script updates the Info.plist file with version information from Git

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFO_PLIST_PATH="${PROJECT_ROOT}/Info.plist"
VERSION_INFO_PLIST_PATH="${PROJECT_ROOT}/Resources/VersionInfo.plist"
GENERATE_VERSION_SCRIPT="${SCRIPT_DIR}/generate-version.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are available
check_dependencies() {
    local missing_tools=()
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if ! command -v plutil &> /dev/null; then
        missing_tools+=("plutil")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        return 1
    fi
    
    return 0
}


# Function to update VersionInfo.plist with Git version info
update_version_info_plist() {
    local build_number
    local version_string
    
    # Get version information from Git
    if [[ -x "$GENERATE_VERSION_SCRIPT" ]]; then
        build_number=$("$GENERATE_VERSION_SCRIPT" build-number)
        version_string=$("$GENERATE_VERSION_SCRIPT" version-string)
    else
        print_error "Version generation script not found or not executable: $GENERATE_VERSION_SCRIPT"
        return 1
    fi
    
    # Validate version information
    if [[ -z "$build_number" || -z "$version_string" ]]; then
        print_error "Failed to get version information from Git"
        return 1
    fi
    
    print_info "Creating VersionInfo.plist with Git version information:"
    print_info "  Version: $version_string"
    print_info "  Build Number: $build_number"
    
    # Create Resources directory if it doesn't exist
    mkdir -p "$(dirname "$VERSION_INFO_PLIST_PATH")"
    
    # Create VersionInfo.plist
    cat > "$VERSION_INFO_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>$version_string</string>
	<key>CFBundleVersion</key>
	<string>$build_number</string>
</dict>
</plist>
EOF
    
    print_info "Successfully created VersionInfo.plist with Git version information"
}

# Function to verify VersionInfo.plist is valid
verify_version_info_plist() {
    if plutil -lint "$VERSION_INFO_PLIST_PATH" > /dev/null 2>&1; then
        print_info "VersionInfo.plist is valid"
        return 0
    else
        print_error "VersionInfo.plist is invalid"
        return 1
    fi
}

# Function to display current version info
display_version_info() {
    local version build_number
    
    if [[ -f "$VERSION_INFO_PLIST_PATH" ]]; then
        version=$(plutil -extract CFBundleShortVersionString raw "$VERSION_INFO_PLIST_PATH" 2>/dev/null || echo "Not set")
        build_number=$(plutil -extract CFBundleVersion raw "$VERSION_INFO_PLIST_PATH" 2>/dev/null || echo "Not set")
        
        print_info "Current version info in VersionInfo.plist:"
        print_info "  Version: $version"
        print_info "  Build Number: $build_number"
    else
        print_info "VersionInfo.plist not found (will be created during build)"
    fi
}

# Main function
main() {
    print_info "Starting version info update process..."
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Make sure we're in a Git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository"
        exit 1
    fi
    
    # Make sure generate-version.sh is executable
    if [[ -f "$GENERATE_VERSION_SCRIPT" ]]; then
        chmod +x "$GENERATE_VERSION_SCRIPT"
    else
        print_error "Version generation script not found: $GENERATE_VERSION_SCRIPT"
        exit 1
    fi
    
    # Display current version info
    display_version_info
    
    # Update VersionInfo.plist with Git version info
    if update_version_info_plist; then
        # Verify the updated VersionInfo.plist is valid
        if verify_version_info_plist; then
            print_info "Version update completed successfully"
            display_version_info
        else
            print_error "VersionInfo.plist validation failed"
            exit 1
        fi
    else
        print_error "Failed to update version info"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [--help]"
        echo "Creates VersionInfo.plist with Git-based version information"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac