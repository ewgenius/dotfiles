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

## Telegram Webhook Setup

The `notify` OpenCode agent uses a helper script to send messages via Telegram. The secret is stored in your system keychain.

### 1. Store the secret

**macOS (Keychain):**
```bash
security add-generic-password -s "ewgenius-webhook-secret" -a "webhook" -w "YOUR_SECRET_HERE"
```

**Ubuntu/Linux (GNOME Keyring) - Desktop only:**
```bash
# Install if needed
sudo apt install gnome-keyring libsecret-tools

# Start the daemon (add to ~/.bashrc or ~/.zshrc for auto-start)
eval $(gnome-keyring-daemon --start --components=secrets)

# Store the secret
secret-tool store --label="ewgenius-webhook-secret" service ewgenius-webhook-secret account webhook
```

**Linux (Headless/SSH) - File-based:**
```bash
# Create secrets directory with restricted permissions
mkdir -p ~/.secrets
chmod 700 ~/.secrets

# Store the secret
echo "YOUR_SECRET_HERE" > ~/.secrets/ewgenius-webhook-secret
chmod 600 ~/.secrets/ewgenius-webhook-secret
```

### 2. Add the script to PATH

The `telegram-send` script is in `~/.config/opencode/scripts/`. Add it to your PATH:

```bash
# Option A: Symlink to a directory in PATH
ln -s ~/.config/opencode/scripts/notify ~/.local/bin/notify

# Option B: Add scripts directory to PATH (in ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.config/opencode/scripts:$PATH"
```

### 3. Verify setup

```bash
# Check secret is stored
# macOS:
security find-generic-password -s "ewgenius-webhook-secret" -a "webhook" -w

# Linux (GNOME Keyring):
secret-tool lookup service ewgenius-webhook-secret account webhook

# Linux (file-based):
cat ~/.secrets/ewgenius-webhook-secret

# Test the script
notify --help
```
