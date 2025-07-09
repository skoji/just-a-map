#!/bin/bash

# Update version info in Info.plist with Git-based versioning
# This script updates the Info.plist file with version information from Git

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFO_PLIST_PATH="${PROJECT_ROOT}/Info.plist"
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

# Function to backup Info.plist
backup_info_plist() {
    local backup_path="${INFO_PLIST_PATH}.backup"
    if [[ -f "$INFO_PLIST_PATH" ]]; then
        cp "$INFO_PLIST_PATH" "$backup_path"
        print_info "Backed up Info.plist to $backup_path"
    fi
}

# Function to restore Info.plist from backup
restore_info_plist() {
    local backup_path="${INFO_PLIST_PATH}.backup"
    if [[ -f "$backup_path" ]]; then
        cp "$backup_path" "$INFO_PLIST_PATH"
        print_info "Restored Info.plist from backup"
    fi
}

# Function to update Info.plist with Git version info
update_info_plist() {
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
    
    print_info "Updating Info.plist with Git version information:"
    print_info "  Version: $version_string"
    print_info "  Build Number: $build_number"
    
    # Update Info.plist using plutil
    if [[ -f "$INFO_PLIST_PATH" ]]; then
        plutil -replace CFBundleShortVersionString -string "$version_string" "$INFO_PLIST_PATH"
        plutil -replace CFBundleVersion -string "$build_number" "$INFO_PLIST_PATH"
        print_info "Successfully updated Info.plist with Git version information"
    else
        print_error "Info.plist not found at $INFO_PLIST_PATH"
        return 1
    fi
}

# Function to verify Info.plist is valid
verify_info_plist() {
    if plutil -lint "$INFO_PLIST_PATH" > /dev/null 2>&1; then
        print_info "Info.plist is valid"
        return 0
    else
        print_error "Info.plist is invalid"
        return 1
    fi
}

# Function to display current version info
display_version_info() {
    local version build_number
    
    version=$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST_PATH" 2>/dev/null || echo "Not set")
    build_number=$(plutil -extract CFBundleVersion raw "$INFO_PLIST_PATH" 2>/dev/null || echo "Not set")
    
    print_info "Current version info in Info.plist:"
    print_info "  Version: $version"
    print_info "  Build Number: $build_number"
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
    if [[ -f "$INFO_PLIST_PATH" ]]; then
        display_version_info
    else
        print_warning "Info.plist not found, will be updated during build"
    fi
    
    # Backup current Info.plist
    backup_info_plist
    
    # Update Info.plist with Git version info
    if update_info_plist; then
        # Verify the updated Info.plist is valid
        if verify_info_plist; then
            print_info "Version update completed successfully"
            display_version_info
        else
            print_error "Info.plist validation failed, restoring backup"
            restore_info_plist
            exit 1
        fi
    else
        print_error "Failed to update version info"
        restore_info_plist
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [--help]"
        echo "Updates Info.plist with Git-based version information"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac