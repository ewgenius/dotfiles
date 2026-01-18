#!/bin/bash
# Desktop module: GUI applications wrapper
# Calls the appropriate platform-specific desktop installer

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PLATFORM=$(detect_platform)

# Check if we have a display
if ! has_display; then
    log_warn "No display detected. Skipping desktop installation."
    log_info "This appears to be a headless/server environment."
    exit 0
fi

log_step "Installing desktop applications..."

case "$PLATFORM" in
    macos)
        source "$SCRIPT_DIR/macos-desktop.sh"
        ;;
    linux)
        source "$SCRIPT_DIR/linux-desktop.sh"
        ;;
    *)
        log_error "Unknown platform: $PLATFORM"
        exit 1
        ;;
esac

# Stow desktop-related configs
stow_package "ghostty"
stow_package "opencode"

log_success "Desktop installation complete!"
