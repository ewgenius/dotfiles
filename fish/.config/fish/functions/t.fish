# Tmux session picker - start/recover/connect
# Usage:
#   t        - pick existing session or create 'main'
#   t .      - new session in current directory (named after folder)
#   t <name> - new session with given name in current directory
function t
  # Handle arguments: create new session in current directory
  if test (count $argv) -gt 0
    set arg $argv[1]
    
    if test "$arg" = "."
      # Use current directory name as session name
      set session_name (basename $PWD)
    else
      # Use provided name
      set session_name $arg
    end
    
    # Check if session already exists
    if tmux has-session -t "=$session_name" 2>/dev/null
      # Attach to existing session
      if test -n "$TMUX"
        tmux switch-client -t "=$session_name"
      else
        tmux attach -t "=$session_name"
      end
    else
      # Create new session in current directory
      if test -n "$TMUX"
        tmux new-session -d -s "$session_name" -c "$PWD"
        tmux switch-client -t "=$session_name"
      else
        tmux new-session -s "$session_name" -c "$PWD"
      end
    end
    return
  end

  # No arguments - show session picker
  
  # Ensure tmux server is running
  tmux start-server 2>/dev/null

  # Trigger resurrect restore if no sessions exist
  if test -z "$(tmux list-sessions 2>/dev/null)"
    tmux new-session -d -s _restore 2>/dev/null
    tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh 2>/dev/null
    sleep 1
    # Kill the temp session if it's empty
    tmux kill-session -t _restore 2>/dev/null
  end

  # Get tmux sessions with window count
  set sessions (tmux list-sessions -F "#{session_name}|#{session_windows} windows|#{?session_attached,attached,}" 2>/dev/null)

  if test -z "$sessions"
    echo "No sessions found. Creating 'main'..."
    tmux new-session -s main
    return
  end

  # Format for fzf: name|windows|attached (keep name intact, use | as delimiter)
  set formatted
  for s in $sessions
    set parts (string split "|" $s)
    set name $parts[1]
    set windows $parts[2]
    set attached $parts[3]
    if test -n "$attached"
      set formatted $formatted "$name|$windows ●"
    else
      set formatted $formatted "$name|$windows"
    end
  end

  # Add option to create new session in current directory
  set current_dir (basename $PWD)
  set formatted "+ new: $current_dir|in $PWD" $formatted

  # Pick session with fzf
  set choice (printf '%s\n' $formatted | fzf --ansi --no-sort --prompt="tmux> " --header="Select session (or create new)" --delimiter="|" --with-nth=1,2)

  if test -n "$choice"
    # Check if user selected "new session" option
    if string match -q "+ new:*" "$choice"
      # Create new session in current directory
      if test -n "$TMUX"
        tmux new-session -d -s "$current_dir" -c "$PWD"
        tmux switch-client -t "=$current_dir"
      else
        tmux new-session -s "$current_dir" -c "$PWD"
      end
    else
      # Extract session name (everything before the first |)
      set session_name (echo $choice | sed 's/|.*//')
      if test -n "$TMUX"
        tmux switch-client -t "=$session_name"
      else
        tmux attach -t "=$session_name"
      end
    end
  end
end
