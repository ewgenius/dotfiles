#!/bin/bash
# Common helper functions for install scripts

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}==>${NC} $1"
}

# Prompt for yes/no with default
# Usage: confirm "message" [y|n]
confirm() {
    local message="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    read -p "$message $prompt " response
    response="${response:-$default}"
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        *)          echo "unknown" ;;
    esac
}

# Check if running in a GUI environment
has_display() {
    if [[ "$(detect_platform)" == "macos" ]]; then
        # macOS always has display unless SSH session without forwarding
        [[ -z "$SSH_CONNECTION" ]] || [[ -n "$DISPLAY" ]]
    else
        # Linux: check for DISPLAY or WAYLAND_DISPLAY
        [[ -n "$DISPLAY" ]] || [[ -n "$WAYLAND_DISPLAY" ]]
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Ensure Homebrew is installed (macOS and Linux)
ensure_homebrew() {
    if ! command_exists brew; then
        log_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add to path for this session
        if [[ "$(detect_platform)" == "macos" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
        else
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
        log_success "Homebrew installed"
    else
        log_success "Homebrew already installed"
    fi
}

# Ensure stow is installed
ensure_stow() {
    if ! command_exists stow; then
        log_step "Installing GNU Stow..."
        if [[ "$(detect_platform)" == "macos" ]]; then
            brew install stow
        else
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y stow
            elif command_exists dnf; then
                sudo dnf install -y stow
            elif command_exists pacman; then
                sudo pacman -S --noconfirm stow
            else
                # Fallback to homebrew on linux
                ensure_homebrew
                brew install stow
            fi
        fi
        log_success "GNU Stow installed"
    else
        log_success "GNU Stow already installed"
    fi
}

# Stow a package with conflict handling
# Usage: stow_package <package_name>
stow_package() {
    local package="$1"
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    
    if [[ ! -d "$dotfiles_dir/$package" ]]; then
        log_warn "Package '$package' not found in $dotfiles_dir"
        return 1
    fi
    
    log_step "Stowing $package..."
    
    # First try to stow, capture conflicts
    if ! stow -d "$dotfiles_dir" -t "$HOME" "$package" 2>&1; then
        log_warn "Conflicts detected for $package, attempting to adopt existing files..."
        stow -d "$dotfiles_dir" -t "$HOME" --adopt "$package"
        # After adopt, restow to ensure dotfiles version wins
        stow -d "$dotfiles_dir" -t "$HOME" -R "$package"
    fi
    
    log_success "Stowed $package"
}

# Unstow a package
unstow_package() {
    local package="$1"
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    
    log_step "Unstowing $package..."
    stow -d "$dotfiles_dir" -t "$HOME" -D "$package" 2>/dev/null || true
    log_success "Unstowed $package"
}

# Install packages from Brewfile
brew_bundle() {
    local brewfile="$1"
    
    if [[ ! -f "$brewfile" ]]; then
        log_warn "Brewfile not found: $brewfile"
        return 1
    fi
    
    log_step "Installing packages from $brewfile..."
    brew bundle --file="$brewfile"
    log_success "Packages installed from $brewfile"
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

# Backup a file or directory
backup_file() {
    local path="$1"
    local backup_dir="${BACKUP_DIR:-$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)}"
    
    if [[ -e "$path" ]] && [[ ! -L "$path" ]]; then
        ensure_dir "$backup_dir"
        local relative="${path#$HOME/}"
        local backup_path="$backup_dir/$relative"
        ensure_dir "$(dirname "$backup_path")"
        cp -R "$path" "$backup_path"
        log_info "Backed up: $path -> $backup_path"
    fi
}

export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
