function dotsync
  cd ~/dotfiles

  # Common packages for all platforms
  set packages fish gemini ghostty git helix opencode tmux

  # Packages that must merge with existing user config (no directory folding)
  set merge_packages pi

  # Platform-specific packages
  if test (uname) = "Darwin"
    set packages $packages macos
  else if test (uname) = "Linux"
    set packages $packages linux
  end

  # Restow all packages to pick up new files
  for pkg in $packages
    if test -d $pkg
      stow -R $pkg 2>/dev/null
    end
  end

  # Restow merge packages with --no-folding to symlink individual files
  # instead of entire directories, preserving user-local files (e.g. auth.json, sessions)
  # --adopt moves existing real files into dotfiles, then git checkout restores our versions
  for pkg in $merge_packages
    if test -d $pkg
      stow -R --no-folding --adopt $pkg 2>/dev/null
      git checkout -- $pkg
    end
  end

  # Reload systemd services on Linux
  if test (uname) = "Linux"; and command -q systemctl
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable --now tmux.service 2>/dev/null
    systemctl --user enable --now opencode.service 2>/dev/null
    systemctl --user enable --now opencode-tailscale.service 2>/dev/null
  end

  git add -A

  # Check if there are changes to commit
  if test -z "$(git status --porcelain)"
    echo "✓ Dotfiles synced (nothing to commit)"
    return 0
  end

  git status
  read -P "Commit message: " msg
  if test -n "$msg"
    git commit -m "$msg"
    git push
    echo "✓ Dotfiles synced"
  else
    echo "Cancelled"
  end
end
