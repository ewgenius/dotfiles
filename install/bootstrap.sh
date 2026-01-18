#!/bin/bash
# Bootstrap script - ensures git is installed and dotfiles repo is cloned
# Can be run standalone via: curl -fsSL https://raw.githubusercontent.com/ewgenius/dotfiles/main/install/bootstrap.sh | bash

set -e

DOTFILES_REPO="https://github.com/ewgenius/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Install git if not present
install_git() {
    local platform=$(detect_platform)
    
    if command_exists git; then
        log_success "Git already installed"
        return 0
    fi
    
    log_info "Installing git..."
    
    case "$platform" in
        macos)
            # Xcode command line tools include git
            xcode-select --install 2>/dev/null || true
            # Wait for installation
            until command_exists git; do
                sleep 5
            done
            ;;
        linux)
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y git
            elif command_exists dnf; then
                sudo dnf install -y git
            elif command_exists pacman; then
                sudo pacman -S --noconfirm git
            elif command_exists apk; then
                sudo apk add git
            else
                log_error "Could not install git - unknown package manager"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown platform"
            exit 1
            ;;
    esac
    
    log_success "Git installed"
}

# Clone dotfiles repo if not present
clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_success "Dotfiles already cloned at $DOTFILES_DIR"
        
        # Pull latest changes
        log_info "Pulling latest changes..."
        cd "$DOTFILES_DIR"
        git pull --ff-only || log_info "Could not pull (might have local changes)"
        return 0
    fi
    
    log_info "Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    log_success "Dotfiles cloned"
}

# Main bootstrap
main() {
    echo ""
    echo -e "${CYAN}Bootstrapping dotfiles...${NC}"
    echo ""
    
    install_git
    clone_dotfiles
    
    # If we're being piped (curl | bash), run the full installer
    if [[ ! -t 0 ]] || [[ "${BOOTSTRAP_ONLY:-}" != "1" ]]; then
        log_info "Running installer..."
        exec "$DOTFILES_DIR/install.sh"
    else
        log_success "Bootstrap complete"
        log_info "Run: ~/dotfiles/install.sh"
    fi
}

main "$@"
