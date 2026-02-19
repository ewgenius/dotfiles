function w
    if test (count $argv) -eq 0
        echo "Usage: w <path> | w close"
        return 1
    end

    set -l cmd $argv[1]

    if test "$cmd" = "close"
        # ---------------------------------------------------------
        # CLOSE SUBCOMMAND
        # ---------------------------------------------------------
        
        # Check git
        if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
            echo "Error: Not inside a git repository."
            return 1
        end

        set -l current_wt (git rev-parse --show-toplevel)
        # Get main worktree path (first line of worktree list porcelain output)
        set -l main_wt (git worktree list --porcelain | head -n1 | string replace 'worktree ' '')
        
        if test "$current_wt" = "$main_wt"
            echo "Error: You are in the main worktree. Cannot close."
            return 1
        end

        set -l wt_name (basename "$current_wt")
        set -l repo_name (basename "$main_wt")

        read -P "Are you sure to delete worktree '$wt_name' for '$repo_name' repo? [y/N] " confirm
        if test "$confirm" != "y" -a "$confirm" != "Y"
            echo "Aborted."
            return 0
        end

        # Move to base repo
        cd "$main_wt"

        # Remove worktree
        if git worktree remove "$current_wt"
            echo "Worktree '$wt_name' removed."
            
            # Tmux handling
            if test -n "$TMUX"
                set -l current_session (tmux display-message -p "#S")
                # If current session matches worktree name
                if test "$current_session" = "$wt_name"
                    # Switch to main repo session (repo_name)
                    # Create if not exists
                    if not tmux has-session -t "=$repo_name" 2>/dev/null
                        tmux new-session -d -s "$repo_name" -c "$main_wt"
                    end
                    tmux switch-client -t "=$repo_name"
                    # Kill old session
                    tmux kill-session -t "$current_session"
                end
            end
        else
            echo "Failed to remove worktree. It might contain modified or untracked files."
            echo "Use 'git worktree remove --force $current_wt' manually if you want to force delete."
            return 1
        end

    else
        # ---------------------------------------------------------
        # CREATE SUBCOMMAND (Default)
        # ---------------------------------------------------------
        set -l path $cmd
        
        # Check if inside git repo
        if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
            echo "Error: Not inside a git repository."
            return 1
        end

        # Check if target directory already exists
        if test -d "$path"
            echo "Error: Directory '$path' already exists."
            return 1
        end

        # Determine default branch
        set -l default_branch ""
        if git symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1
            set default_branch (git symbolic-ref refs/remotes/origin/HEAD | string replace 'refs/remotes/' '')
        else if git rev-parse --verify origin/main >/dev/null 2>&1
            set default_branch "origin/main"
        else if git rev-parse --verify origin/master >/dev/null 2>&1
            set default_branch "origin/master"
        else
            echo "Error: Could not determine default branch."
            return 1
        end

        # Branch name from path basename
        set -l clean_path (string trim -r -c / "$path")
        set -l branch_name (basename "$clean_path")
        
        echo "Creating worktree at '$path'..."

        # Check if branch exists locally
        if git show-ref --verify --quiet "refs/heads/$branch_name"
            echo "Branch '$branch_name' exists. Checking out..."
            if not git worktree add "$path" "$branch_name"
                 echo "Error: Failed to checkout existing branch '$branch_name'."
                 return 1
            end
        else
            echo "Creating new branch '$branch_name' from '$default_branch'..."
            if not git worktree add -b "$branch_name" "$path" "$default_branch"
                 echo "Error: Failed to create new worktree/branch."
                 return 1
            end
        end

        # Resolve absolute path for tmux
        pushd "$path" >/dev/null
        set -l abs_path (pwd)
        popd >/dev/null

        # Tmux session name = branch name
        set -l session_name "$branch_name"
        
        # Switch/Create tmux session
        if tmux has-session -t "=$session_name" 2>/dev/null
            if test -n "$TMUX"
                tmux switch-client -t "=$session_name"
            else
                tmux attach -t "=$session_name"
            end
        else
            if test -n "$TMUX"
                tmux new-session -d -s "$session_name" -c "$abs_path"
                tmux switch-client -t "=$session_name"
            else
                tmux new-session -s "$session_name" -c "$abs_path"
            end
        end
    end
end
