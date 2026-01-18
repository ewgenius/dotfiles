#!/bin/bash
# macOS Desktop: GUI applications
# Installs: Ghostty, fonts, and other desktop apps

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ "$(detect_platform)" != "macos" ]]; then
    log_error "This script is for macOS only"
    exit 1
fi

log_step "Installing macOS desktop applications..."

ensure_homebrew

# Desktop apps Brewfile (casks)
BREWFILE="$DOTFILES_DIR/Brewfile.desktop"
if [[ -f "$BREWFILE" ]]; then
    brew_bundle "$BREWFILE"
else
    log_step "Installing desktop applications..."
    
    # Terminal
    brew install --cask ghostty
    
    # Fonts (free alternatives - Berkeley Mono needs manual install)
    brew install --cask font-jetbrains-mono
    brew install --cask font-jetbrains-mono-nerd-font
    brew install --cask font-fira-code
    brew install --cask font-fira-code-nerd-font
    
    # Optional apps - prompt for each
    if confirm "Install Arc browser?" "n"; then
        brew install --cask arc
    fi
    
    if confirm "Install VS Code?" "n"; then
        brew install --cask visual-studio-code
    fi
    
    if confirm "Install Raycast?" "y"; then
        brew install --cask raycast
    fi
    
    if confirm "Install Rectangle (window management)?" "y"; then
        brew install --cask rectangle
    fi
    
    if confirm "Install 1Password?" "n"; then
        brew install --cask 1password
    fi
fi

# Remind about licensed fonts
log_info ""
log_info "Note: Berkeley Mono is a licensed font and must be installed manually."
log_info "Download from: https://berkeleygraphics.com/typefaces/berkeley-mono/"
log_info ""

log_success "macOS desktop applications installed!"
