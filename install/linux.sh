#!/bin/bash
# Linux-specific setup
# Installs Linux-specific tools and configurations

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ "$(detect_platform)" != "linux" ]]; then
    log_error "This script is for Linux only"
    exit 1
fi

log_step "Configuring Linux..."

# Detect distro
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
    log_info "Detected distro: $DISTRO"
else
    DISTRO="unknown"
fi

# Install build essentials for compiling tools
if command_exists apt-get; then
    log_step "Installing build essentials..."
    sudo apt-get update
    sudo apt-get install -y build-essential curl git
elif command_exists dnf; then
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y curl git
elif command_exists pacman; then
    sudo pacman -S --noconfirm base-devel curl git
fi

# Setup Homebrew on Linux (optional but recommended for consistency)
if confirm "Install Homebrew for Linux? (recommended for tool consistency)" "y"; then
    ensure_homebrew
    
    # Add to fish config
    FISH_BREW_CONF="$HOME/.config/fish/conf.d/homebrew.fish"
    if [[ ! -f "$FISH_BREW_CONF" ]]; then
        mkdir -p "$(dirname "$FISH_BREW_CONF")"
        cat > "$FISH_BREW_CONF" << 'EOF'
# Homebrew on Linux
if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end
EOF
        log_success "Homebrew fish integration configured"
    fi
fi

# Linux-specific packages
if [[ -f "$DOTFILES_DIR/packages.linux.txt" ]]; then
    log_step "Installing Linux-specific packages..."
    if command_exists apt-get; then
        xargs -a "$DOTFILES_DIR/packages.linux.txt" sudo apt-get install -y
    elif command_exists dnf; then
        xargs -a "$DOTFILES_DIR/packages.linux.txt" sudo dnf install -y
    elif command_exists pacman; then
        xargs -a "$DOTFILES_DIR/packages.linux.txt" sudo pacman -S --noconfirm
    fi
fi

# Stow Linux-specific configs (systemd services)
stow_package "linux"

# Enable and start systemd user services
if command_exists systemctl; then
    systemctl --user daemon-reload
    systemctl --user enable --now tmux.service
    systemctl --user enable --now opencode.service
    systemctl --user enable --now opencode-tailscale.service
    log_success "Systemd user services enabled and started"
fi

log_success "Linux setup complete!"
