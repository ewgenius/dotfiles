if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting ""

# Fix TERM for tmux on Linux (SSH from Ghostty)
if test (uname) = "Linux"
    set -gx TERM xterm-256color
end

# Default editor
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx KUBE_EDITOR nvim

# Homebrew (macOS arm64, macOS x86, or Linux)
if test -f /opt/homebrew/bin/brew
    eval "$(/opt/homebrew/bin/brew shellenv)"
else if test -f /usr/local/bin/brew
    eval "$(/usr/local/bin/brew shellenv)"
else if test -f /home/linuxbrew/.linuxbrew/bin/brew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
end

# asdf version manager
if test -f $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
    source $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
else if test -f ~/.asdf/asdf.fish
    source ~/.asdf/asdf.fish
end
if test -d ~/.asdf/shims
    fish_add_path ~/.asdf/shims
end

# Golang (via asdf)
if test -d ~/.asdf/installs/golang
    set -l go_version (ls ~/.asdf/installs/golang 2>/dev/null | tail -1)
    if test -n "$go_version"
        set -gx GOPATH ~/.asdf/installs/golang/$go_version/go
        fish_add_path $GOPATH/bin
    end
end

# Rust
fish_add_path ~/.cargo/bin

# Bun
if test -d ~/.bun
    set -gx BUN_INSTALL ~/.bun
    fish_add_path $BUN_INSTALL/bin
end

# Node (Homebrew)
if test -d $HOMEBREW_PREFIX/opt/node@22/bin
    fish_add_path $HOMEBREW_PREFIX/opt/node@22/bin
end

# Java (Homebrew)
if test -d $HOMEBREW_PREFIX/opt/openjdk@17
    fish_add_path $HOMEBREW_PREFIX/opt/openjdk@17/bin
    set -gx JAVA_HOME $HOMEBREW_PREFIX/opt/openjdk@17
end

# Android SDK
if test -d ~/Library/Android/sdk
    set -gx ANDROID_HOME ~/Library/Android/sdk
    set -gx ANDROID_SDK_ROOT ~/Library/Android/sdk
    fish_add_path $ANDROID_HOME/platform-tools
    fish_add_path $ANDROID_HOME/emulator
    fish_add_path $ANDROID_HOME/tools/bin
end

# Local bin
fish_add_path ~/.local/bin

# Starship prompt
if command -q starship
    set -l starship_init (starship init fish 2>/dev/null)
    test -n "$starship_init" && echo $starship_init | source
end

# fzf - use --fish for 0.48+, otherwise try legacy key-bindings
if command -q fzf
    set -l fzf_init (fzf --fish 2>/dev/null)
    if test -n "$fzf_init"
        echo $fzf_init | source
    else if test -f /usr/share/doc/fzf/examples/key-bindings.fish
        source /usr/share/doc/fzf/examples/key-bindings.fish
    end
end

# zoxide
if command -q zoxide
    set -l zoxide_init (zoxide init fish 2>/dev/null)
    test -n "$zoxide_init" && echo $zoxide_init | source
end

# Wasmer
if test -d ~/.wasmer
    set -gx WASMER_DIR ~/.wasmer
    fish_add_path $WASMER_DIR/bin
end

# Modular/Mojo
if test -d ~/.modular
    set -gx MODULAR_HOME ~/.modular
    fish_add_path ~/.modular/pkg/packages.modular.com_mojo/bin
end

# OpenCode
fish_add_path ~/.opencode/bin

# OrbStack (macOS)
if test -f ~/.orbstack/shell/init.fish
    source ~/.orbstack/shell/init.fish
end

# Tailscale (macOS app)
if test -f /Applications/Tailscale.app/Contents/MacOS/Tailscale
    alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
end

# Claude CLI
if test -f ~/.claude/local/claude
    alias claude="~/.claude/local/claude"
end

# LM Studio
if test -d ~/.cache/lm-studio/bin
    fish_add_path ~/.cache/lm-studio/bin
end

# tmux settings
set -gx TINTED_TMUX_OPTION_ACTIVE 1
set -gx TINTED_TMUX_OPTION_STATUSBAR 1

# ============================================
# Machine-specific paths (add as needed)
# ============================================
# Spice development
if test -d ~/Developer/Spice/spiceai/target/debug
    fish_add_path ~/Developer/Spice/spiceai/target/debug
end
fish_add_path ~/.spice/bin

# Personal projects
fish_add_path ~/Developer/Personal/broom/dist
fish_add_path ~/Developer/Personal/gyrus/dist
fish_add_path ~/Developer/Tools/bin

# opencode
fish_add_path /Users/evgenii/.opencode/bin

# gyrus alias
alias g gyrus
