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
    # Linux without Homebrew - use native package manager + manual installs
    log_step "Installing base packages via system package manager..."
    
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y fish tmux fzf ripgrep fd-find bat jq curl unzip wget gpg
        
        # Install starship
        if ! command_exists starship; then
            log_step "Installing starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
        
        # Install zoxide
        if ! command_exists zoxide; then
            log_step "Installing zoxide..."
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        fi
        
        # Install eza (modern ls)
        if ! command_exists eza; then
            log_step "Installing eza..."
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo apt-get update
            sudo apt-get install -y eza
        fi
        
        # Install helix via snap (PPA doesn't support all Ubuntu versions)
        if ! command_exists hx; then
            log_step "Installing helix..."
            if command_exists snap; then
                sudo snap install helix --classic
            else
                # Fallback: download binary
                HELIX_VERSION=$(curl -sL https://api.github.com/repos/helix-editor/helix/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
                ARCH=$(uname -m)
                if [[ "$ARCH" == "aarch64" ]]; then
                    curl -sL "https://github.com/helix-editor/helix/releases/latest/download/helix-${HELIX_VERSION}-aarch64-linux.tar.xz" | sudo tar -xJ -C /opt
                    sudo ln -sf "/opt/helix-${HELIX_VERSION}-aarch64-linux/hx" /usr/local/bin/hx
                else
                    curl -sL "https://github.com/helix-editor/helix/releases/latest/download/helix-${HELIX_VERSION}-x86_64-linux.tar.xz" | sudo tar -xJ -C /opt
                    sudo ln -sf "/opt/helix-${HELIX_VERSION}-x86_64-linux/hx" /usr/local/bin/hx
                fi
            fi
        fi
        
        log_warn "sesh, git-delta may need manual installation or use Homebrew"
        
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
stow_package "pi"

# Set fish as default shell if not already
if [[ "$SHELL" != *"fish"* ]]; then
    FISH_PATH=$(which fish)
    if [[ -n "$FISH_PATH" ]]; then
        if ! grep -q "$FISH_PATH" /etc/shells; then
            log_step "Adding fish to /etc/shells..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells
        fi
        
        if confirm "Set fish as default shell?" "y"; then
            chsh -s "$FISH_PATH" || sudo chsh -s "$FISH_PATH" "$USER" || log_warn "Could not change shell, run manually: chsh -s $FISH_PATH"
        fi
    fi
fi

# Create ~/.local/bin if needed
ensure_dir "$HOME/.local/bin"

log_success "Base installation complete!"
log_info "Note: Run 'tmux' and press Ctrl+b I to install tmux plugins"
