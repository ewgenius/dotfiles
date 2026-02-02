# Daily note creator
# Usage:
#   note        - create/open today's note at ~/Documents/Notes/YYYY-MM-DD.md
#   note <date> - create/open note for specific date (e.g., note 2024-01-15)
function note
  set notes_dir ~/Documents/Notes
  
  # Ensure notes directory exists
  if not test -d $notes_dir
    mkdir -p $notes_dir
  end
  
  # Determine the date for the note
  if test (count $argv) -gt 0
    set note_date $argv[1]
  else
    set note_date (date +%Y-%m-%d)
  end
  
  set note_path "$notes_dir/$note_date.md"
  
  # Create note with template if it doesn't exist
  if not test -f $note_path
    echo "# $note_date" > $note_path
    echo "" >> $note_path
    echo "## Notes" >> $note_path
    echo "" >> $note_path
    echo "Created: $(date '+%Y-%m-%d %H:%M')" >> $note_path
  end
  
  # Open the note in the default editor
  if test -n "$EDITOR"
    $EDITOR $note_path
  else
    # Fallback to common editors
    if command -q hx
      hx $note_path
    else if command -q nvim
      nvim $note_path
    else if command -q vim
      vim $note_path
    else if command -q nano
      nano $note_path
    else
      echo "No editor found. Note created at: $note_path"
    end
  end
end