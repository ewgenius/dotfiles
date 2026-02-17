function dotrestore
  set name $argv[1]
  if test -z "$name"
    echo "Usage: dotrestore <backup-name>"
    echo "Available backups:"
    dotbackups
    return 1
  end
  
  set backup_dir ~/.dotfiles-backups/$name
  if not test -d $backup_dir
    echo "Backup not found: $name"
    return 1
  end
  
  # Remove current symlinks/files and restore
  rm -rf ~/.config/fish ~/.tmux.conf ~/.config/helix ~/.config/opencode ~/.gemini ~/.config/ghostty ~/.gitconfig
  
  cp -r $backup_dir/fish ~/.config/ 2>/dev/null
  cp $backup_dir/.tmux.conf ~/ 2>/dev/null
  cp -r $backup_dir/helix ~/.config/ 2>/dev/null
  cp -r $backup_dir/opencode ~/.config/ 2>/dev/null
  cp -r $backup_dir/.gemini ~/ 2>/dev/null
  cp -r $backup_dir/ghostty ~/.config/ 2>/dev/null
  cp $backup_dir/.gitconfig ~/ 2>/dev/null
  
  echo "✓ Restored from: $name"
end
