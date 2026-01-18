#!/bin/bash
# Base module: Cross-platform CLI tools
# Installs: fish, tmux, helix, fzf, sesh, ripgrep, fd, bat, eza, zoxide, starship, git-delta

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log_step "Installing base CLI tools..."

PLATFORM=$(detect_platform)

# Ensure stow is available
ensure_stow

if [[ "$PLATFORM" == "macos" ]] || command_exists brew; then
    # Use Homebrew (works on both macOS and Linux)
    ensure_homebrew
    
    BREWFILE="$DOTFILES_DIR/Brewfile.base"
    if [[ -f "$BREWFILE" ]]; then
        brew_bundle "$BREWFILE"
    else
        # Fallback: install individually
        log_step "Installing base packages via Homebrew..."
        brew install fish tmux helix fzf ripgrep fd bat eza zoxide starship git-delta sesh jq
    fi
else
    # Linux without Homebrew - use native package manager
    log_step "Installing base packages via system package manager..."
    
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y fish tmux fzf ripgrep fd-find bat zoxide jq
        # Some packages need manual install on Debian/Ubuntu
        log_warn "helix, eza, starship, git-delta, sesh may need manual installation"
        log_info "Run: curl -sS https://starship.rs/install.sh | sh"
        
    elif command_exists dnf; then
        sudo dnf install -y fish tmux fzf ripgrep fd-find bat eza zoxide jq
        log_warn "helix, starship, git-delta, sesh may need manual installation"
        
    elif command_exists pacman; then
        sudo pacman -S --noconfirm fish tmux helix fzf ripgrep fd bat eza zoxide starship git-delta jq
        log_warn "sesh may need manual installation from AUR"
    else
        log_error "Unsupported package manager. Consider installing Homebrew."
        exit 1
    fi
fi

# Install TPM (Tmux Plugin Manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_step "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    log_success "TPM installed"
else
    log_success "TPM already installed"
fi

# Stow base configurations
log_step "Linking configuration files..."
stow_package "fish"
stow_package "tmux"
stow_package "helix"
stow_package "git"

# Set fish as default shell if not already
if [[ "$SHELL" != *"fish"* ]]; then
    FISH_PATH=$(which fish)
    if [[ -n "$FISH_PATH" ]]; then
        if ! grep -q "$FISH_PATH" /etc/shells; then
            log_step "Adding fish to /etc/shells..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells
        fi
        
        if confirm "Set fish as default shell?" "y"; then
            chsh -s "$FISH_PATH"
            log_success "Fish set as default shell"
        fi
    fi
fi

# Create ~/.local/bin if needed
ensure_dir "$HOME/.local/bin"

log_success "Base installation complete!"
log_info "Note: Run 'tmux' and press Ctrl+b I to install tmux plugins"
