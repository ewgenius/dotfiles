# dotfiles

Personal dotfiles for [@ewgenius](https://github.com/ewgenius).

Cross-platform configuration for fish, tmux, helix, git, ghostty, and more.

## Quick Start

### One-liner (fresh machine)

```bash
curl -fsSL https://raw.githubusercontent.com/ewgenius/dotfiles/main/install.sh | bash
```

This will:
1. Install git if needed
2. Clone the repo to `~/dotfiles`
3. Run the interactive installer

### Manual Setup

```bash
git clone https://github.com/ewgenius/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Manual Stow

If you prefer to link configs manually:

```bash
cd ~/dotfiles
stow fish      # ~/.config/fish/
stow tmux      # ~/.tmux.conf + ~/.local/bin/tmux-ai-rename
stow git       # ~/.gitconfig
stow helix     # ~/.config/helix/
stow ghostty   # ~/.config/ghostty/
stow opencode  # ~/.config/opencode/
stow macos     # macOS LaunchAgent (optional)
```

## Structure

```
~/dotfiles/
├── fish/           # Fish shell config + functions
├── tmux/           # Tmux config + scripts
├── git/            # Git config (conditional includes)
├── helix/          # Helix editor config + themes
├── ghostty/        # Ghostty terminal config
├── opencode/       # OpenCode AI assistant config
├── macos/          # macOS-specific (LaunchAgent)
├── install/        # Installation scripts
│   ├── bootstrap.sh   # Git + clone (curl-able)
│   ├── common.sh      # Shared functions
│   ├── base.sh        # CLI tools
│   ├── macos.sh       # macOS setup
│   ├── linux.sh       # Linux setup
│   └── desktop.sh     # GUI apps
├── Brewfile.*      # Homebrew packages
└── packages.*.txt  # Linux packages
```

## Requirements

Installed automatically:
- [Homebrew](https://brew.sh)
- [GNU Stow](https://www.gnu.org/software/stow/)
