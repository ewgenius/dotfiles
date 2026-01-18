#!/bin/bash
# Dotfiles installer
# Usage:
#   Fresh machine:  curl -fsSL https://raw.githubusercontent.com/ewgenius/dotfiles/main/install.sh | bash
#   Existing clone: ./install.sh

set -e

# If dotfiles not cloned yet, run bootstrap first
if [[ ! -f "$HOME/dotfiles/install/common.sh" ]]; then
    echo "Dotfiles not found, bootstrapping..."
    curl -fsSL https://raw.githubusercontent.com/ewgenius/dotfiles/main/install/bootstrap.sh | bash
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="$SCRIPT_DIR"

source "$SCRIPT_DIR/install/common.sh"

# Header
echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}         ${GREEN}Dotfiles Installer${NC}             ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

PLATFORM=$(detect_platform)
HAS_DISPLAY=$(has_display && echo "yes" || echo "no")

log_info "Platform: $PLATFORM"
log_info "Display available: $HAS_DISPLAY"
echo ""

# Backup existing configs
if confirm "Create backup of existing dotfiles?" "y"; then
    export BACKUP_DIR="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
    log_step "Backing up to $BACKUP_DIR..."
    
    backup_file "$HOME/.config/fish"
    backup_file "$HOME/.config/helix"
    backup_file "$HOME/.config/ghostty"
    backup_file "$HOME/.config/opencode"
    backup_file "$HOME/.tmux.conf"
    backup_file "$HOME/.gitconfig"
    
    log_success "Backup complete: $BACKUP_DIR"
fi

echo ""
echo -e "${CYAN}Select modules to install:${NC}"
echo ""

# Base module (always recommended)
INSTALL_BASE="n"
if confirm "Install base CLI tools? (fish, tmux, helix, fzf, etc.)" "y"; then
    INSTALL_BASE="y"
fi

# Platform-specific module
INSTALL_PLATFORM="n"
if [[ "$PLATFORM" == "macos" ]]; then
    if confirm "Apply macOS-specific configuration?" "y"; then
        INSTALL_PLATFORM="y"
    fi
elif [[ "$PLATFORM" == "linux" ]]; then
    if confirm "Apply Linux-specific configuration?" "y"; then
        INSTALL_PLATFORM="y"
    fi
fi

# Desktop module (only if display available)
INSTALL_DESKTOP="n"
if [[ "$HAS_DISPLAY" == "yes" ]]; then
    if confirm "Install desktop applications? (Ghostty, fonts)" "y"; then
        INSTALL_DESKTOP="y"
    fi
else
    log_info "Skipping desktop module (no display detected)"
fi

echo ""
log_step "Installation summary:"
echo "  Base CLI tools: $INSTALL_BASE"
echo "  Platform config ($PLATFORM): $INSTALL_PLATFORM"
echo "  Desktop apps: $INSTALL_DESKTOP"
echo ""

if ! confirm "Proceed with installation?" "y"; then
    log_info "Installation cancelled"
    exit 0
fi

echo ""

# Run selected modules
if [[ "$INSTALL_BASE" == "y" ]]; then
    source "$SCRIPT_DIR/install/base.sh"
    echo ""
fi

if [[ "$INSTALL_PLATFORM" == "y" ]]; then
    if [[ "$PLATFORM" == "macos" ]]; then
        source "$SCRIPT_DIR/install/macos.sh"
    else
        source "$SCRIPT_DIR/install/linux.sh"
    fi
    echo ""
fi

if [[ "$INSTALL_DESKTOP" == "y" ]]; then
    source "$SCRIPT_DIR/install/desktop.sh"
    echo ""
fi

# Final messages
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}       ${CYAN}Installation Complete!${NC}            ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
log_info "Next steps:"
echo "  1. Restart your terminal (or run: exec fish)"
echo "  2. In tmux, press Ctrl+b I to install plugins"
echo "  3. Run 'starship init fish | source' if prompt looks wrong"
echo ""

if [[ -n "$BACKUP_DIR" ]]; then
    log_info "Backup location: $BACKUP_DIR"
    log_info "To restore: dotrestore $BACKUP_DIR"
fi
