function dotsync
  cd ~/dotfiles
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
