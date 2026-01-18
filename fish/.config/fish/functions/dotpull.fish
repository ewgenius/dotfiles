function dotpull
  cd ~/dotfiles
  git pull
  # Re-stow to update symlinks
  for dir in fish tmux opencode helix ghostty git
    test -d $dir && stow -R $dir
  end
  echo "✓ Dotfiles updated"
end
