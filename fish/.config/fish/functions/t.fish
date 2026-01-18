# Tmux session picker - start/recover/connect
function t
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

  # Pick session with fzf (display with | replaced by tab for readability)
  set choice (printf '%s\n' $formatted | fzf --ansi --no-sort --prompt="tmux> " --header="Select session" --delimiter="|" --with-nth=1,2)

  if test -n "$choice"
    # Extract session name (everything before the first |)
    set session_name (echo $choice | sed 's/|.*//')
    if test -n "$TMUX"
      tmux switch-client -t "=$session_name"
    else
      tmux attach -t "=$session_name"
    end
  end
end
