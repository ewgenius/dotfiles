function dotpull
  cd ~/dotfiles
  git pull
  
  # Common packages for all platforms
  set packages fish gemini ghostty git helix opencode tmux
  
  # Platform-specific packages
  if test (uname) = "Darwin"
    set packages $packages macos
  end
  
  # Re-stow to update symlinks
  for pkg in $packages
    test -d $pkg && stow -R $pkg
  end
  
  # Reload systemd service on Linux
  if test (uname) = "Linux"; and command -q systemctl
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable --now tmux.service 2>/dev/null
  end
  
  echo "✓ Dotfiles updated"
end
