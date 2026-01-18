#!/bin/bash
# Linux Desktop: GUI applications
# Installs: Ghostty, fonts, and other desktop apps

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ "$(detect_platform)" != "linux" ]]; then
    log_error "This script is for Linux only"
    exit 1
fi

log_step "Installing Linux desktop applications..."

# Detect distro
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
fi

# Install Ghostty
if ! command_exists ghostty; then
    log_step "Installing Ghostty..."
    
    case "$DISTRO" in
        arch|manjaro)
            # Ghostty is in AUR
            if command_exists yay; then
                yay -S --noconfirm ghostty
            elif command_exists paru; then
                paru -S --noconfirm ghostty
            else
                log_warn "Please install an AUR helper (yay/paru) or build Ghostty manually"
            fi
            ;;
        ubuntu|debian|pop)
            # Build from source or use unofficial PPA
            log_warn "Ghostty needs to be built from source on $DISTRO"
            log_info "See: https://github.com/ghostty-org/ghostty"
            log_info "Or use the snap: snap install ghostty"
            if confirm "Try installing via snap?" "y"; then
                sudo snap install ghostty
            fi
            ;;
        fedora)
            # Check for COPR
            log_info "Installing Ghostty via COPR..."
            sudo dnf copr enable -y pgdev/ghostty 2>/dev/null || true
            sudo dnf install -y ghostty || log_warn "Ghostty installation failed, may need manual build"
            ;;
        *)
            log_warn "Please install Ghostty manually for $DISTRO"
            ;;
    esac
fi

# Install fonts
log_step "Installing fonts..."
case "$DISTRO" in
    arch|manjaro)
        sudo pacman -S --noconfirm ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-fira-code
        ;;
    ubuntu|debian|pop)
        sudo apt-get install -y fonts-jetbrains-mono fonts-firacode
        # Nerd fonts need manual install
        log_info "Installing JetBrains Mono Nerd Font..."
        FONT_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"
        curl -fLo "$FONT_DIR/JetBrainsMono.zip" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
        unzip -o "$FONT_DIR/JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono"
        rm "$FONT_DIR/JetBrainsMono.zip"
        fc-cache -fv
        ;;
    fedora)
        sudo dnf install -y jetbrains-mono-fonts fira-code-fonts
        ;;
esac

# Desktop packages file
if [[ -f "$DOTFILES_DIR/packages.desktop.txt" ]]; then
    log_step "Installing additional desktop packages..."
    case "$DISTRO" in
        arch|manjaro)
            xargs -a "$DOTFILES_DIR/packages.desktop.txt" sudo pacman -S --noconfirm
            ;;
        ubuntu|debian|pop)
            xargs -a "$DOTFILES_DIR/packages.desktop.txt" sudo apt-get install -y
            ;;
        fedora)
            xargs -a "$DOTFILES_DIR/packages.desktop.txt" sudo dnf install -y
            ;;
    esac
fi

log_info ""
log_info "Note: Berkeley Mono is a licensed font and must be installed manually."
log_info ""

log_success "Linux desktop applications installed!"
