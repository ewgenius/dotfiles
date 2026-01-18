function dotbackups
  if test -d ~/.dotfiles-backups
    ls -1 ~/.dotfiles-backups/
  else
    echo "No backups found"
  end
end
