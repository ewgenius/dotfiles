function dotsync
  cd ~/dotfiles
  
  # Common packages for all platforms
  set packages fish ghostty git helix opencode tmux
  
  # Platform-specific packages
  if test (uname) = "Darwin"
    set packages $packages macos
  end
  
  # Restow all packages to pick up new files
  for pkg in $packages
    if test -d $pkg
      stow -R $pkg 2>/dev/null
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
