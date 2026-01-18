#!/bin/bash
# macOS-specific setup
# Configures macOS defaults and installs macOS-specific CLI tools

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ "$(detect_platform)" != "macos" ]]; then
    log_error "This script is for macOS only"
    exit 1
fi

log_step "Configuring macOS..."

# Install Xcode Command Line Tools if needed
if ! xcode-select -p &>/dev/null; then
    log_step "Installing Xcode Command Line Tools..."
    xcode-select --install
    log_info "Please complete the Xcode tools installation and re-run this script"
    exit 0
fi

# Ensure Homebrew
ensure_homebrew

# macOS-specific Brewfile
BREWFILE="$DOTFILES_DIR/Brewfile.macos"
if [[ -f "$BREWFILE" ]]; then
    brew_bundle "$BREWFILE"
fi

# macOS defaults
if confirm "Apply recommended macOS defaults?" "y"; then
    log_step "Applying macOS defaults..."
    
    # Keyboard
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    
    # Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    # Dock
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock tilesize -int 48
    
    # Screenshots
    defaults write com.apple.screencapture location -string "$HOME/Desktop"
    defaults write com.apple.screencapture type -string "png"
    defaults write com.apple.screencapture disable-shadow -bool true
    
    # Trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    
    # Safari (if used)
    defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
    
    # Disable auto-correct annoyances
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # Restart affected apps
    for app in "Dock" "Finder" "Safari"; do
        killall "$app" &>/dev/null || true
    done
    
    log_success "macOS defaults applied"
fi

# Setup LaunchAgent for tmux autostart
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.evgenii.tmux.plist"
if [[ -f "$DOTFILES_DIR/macos/Library/LaunchAgents/com.evgenii.tmux.plist" ]]; then
    stow_package "macos"
    launchctl load "$LAUNCH_AGENT" 2>/dev/null || true
    log_success "Tmux LaunchAgent configured"
fi

log_success "macOS setup complete!"
