function dotsync
  cd ~/dotfiles
  
  # Restow all packages to pick up new files
  for pkg in fish ghostty git helix macos opencode tmux
    if test -d $pkg
      stow -R $pkg 2>/dev/null
    end
  end
  
  git add -A
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
