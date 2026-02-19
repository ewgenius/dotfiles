function w -a path
    # Check if inside git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Error: Not inside a git repository."
        return 1
    end

    if test -z "$path"
        echo "Usage: w <path>"
        return 1
    end
    
    # Check if target directory already exists
    if test -d "$path"
        echo "Error: Directory '$path' already exists."
        return 1
    end

    # Determine default branch
    # Try origin/HEAD, then origin/main, then origin/master
    set -l default_branch ""
    if git symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1
        # Extract branch name from ref
        set default_branch (git symbolic-ref refs/remotes/origin/HEAD | string replace 'refs/remotes/' '')
    else if git rev-parse --verify origin/main >/dev/null 2>&1
        set default_branch "origin/main"
    else if git rev-parse --verify origin/master >/dev/null 2>&1
        set default_branch "origin/master"
    else
        echo "Error: Could not determine default branch (origin/HEAD, origin/main, or origin/master not found)."
        return 1
    end

    # Branch name from path basename
    # Remove trailing slash if present
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
    # Use pushd/popd to be safe
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
