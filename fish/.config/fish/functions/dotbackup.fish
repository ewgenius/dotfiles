function dotbackup
  set name (date +%Y%m%d-%H%M%S)
  set backup_dir ~/.dotfiles-backups/$name
  mkdir -p $backup_dir
  
  # Copy current configs (follow symlinks, get actual files)
  cp -rL ~/.config/fish $backup_dir/ 2>/dev/null
  cp -rL ~/.tmux.conf $backup_dir/ 2>/dev/null
  cp -rL ~/.config/helix $backup_dir/ 2>/dev/null
  cp -rL ~/.config/opencode $backup_dir/ 2>/dev/null
  cp -rL ~/.gemini $backup_dir/ 2>/dev/null
  cp -rL ~/.config/ghostty $backup_dir/ 2>/dev/null
  cp -rL ~/.gitconfig $backup_dir/ 2>/dev/null
  
  echo "✓ Backup created: $backup_dir"
end
