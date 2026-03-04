# Git worktree manager
# Usage:
#   w <name>   - create worktree at sibling path, prints the resolved path
#   w close    - remove current worktree and return to main
function w
    if test (count $argv) -eq 0
        echo "Usage: w <worktree-name> | w close"
        return 1
    end

    set -l cmd $argv[1]

    if test "$cmd" = "close"
        # ---------------------------------------------------------
        # CLOSE SUBCOMMAND
        # ---------------------------------------------------------

        # Check git
        if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
            echo "Error: Not inside a git repository." >&2
            return 1
        end

        set -l current_wt (git rev-parse --show-toplevel)
        # Get main worktree path (first line of worktree list porcelain output)
        set -l main_wt (git worktree list --porcelain | head -n1 | string replace 'worktree ' '')

        if test "$current_wt" = "$main_wt"
            echo "Error: You are in the main worktree. Cannot close." >&2
            return 1
        end

        # Calculate worktree name relative to parent of main repo
        set -l main_parent (dirname "$main_wt")
        set -l wt_name (string replace "$main_parent/" "" "$current_wt")
        set -l repo_name (basename "$main_wt")

        read -P "Are you sure to delete worktree '$wt_name' for '$repo_name' repo? [y/N] " confirm
        if test "$confirm" != "y" -a "$confirm" != "Y"
            echo "Aborted." >&2
            return 0
        end

        # Move to base repo
        cd "$main_wt"

        # Remove worktree
        if git worktree remove "$current_wt"
            echo "Worktree '$wt_name' removed." >&2
        else
            echo "Failed to remove worktree. It might contain modified or untracked files." >&2
            echo "Use 'git worktree remove --force $current_wt' manually if you want to force delete." >&2
            return 1
        end

    else
        # ---------------------------------------------------------
        # CREATE SUBCOMMAND
        # ---------------------------------------------------------
        set -l wt_name $cmd

        # Check if inside git repo
        if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
            echo "Error: Not inside a git repository." >&2
            return 1
        end

        # Calculate target path (sibling to current repo root)
        set -l repo_root (git rev-parse --show-toplevel)
        set -l parent_dir (dirname "$repo_root")
        set -l path "$parent_dir/$wt_name"

        # Check if target directory already exists
        if test -d "$path"
            echo "Error: Directory '$path' already exists." >&2
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
            echo "Error: Could not determine default branch." >&2
            return 1
        end

        set -l branch_name "$wt_name"

        # Ensure parent directory exists (for nested names like group/feature)
        set -l target_parent (dirname "$path")
        if not test -d "$target_parent"
            mkdir -p "$target_parent"
        end

        echo "Creating worktree at '$path'..." >&2

        # Check if branch exists locally
        if git show-ref --verify --quiet "refs/heads/$branch_name"
            echo "Branch '$branch_name' exists. Checking out..." >&2
            if not git worktree add "$path" "$branch_name" >&2
                echo "Error: Failed to checkout existing branch '$branch_name'." >&2
                return 1
            end
        else
            echo "Creating new branch '$branch_name' from '$default_branch'..." >&2
            if not git worktree add -b "$branch_name" "$path" "$default_branch" >&2
                echo "Error: Failed to create new worktree/branch." >&2
                return 1
            end
        end

        # Resolve and print the absolute path (stdout, for callers to capture)
        pushd "$path" >/dev/null
        echo (pwd)
        popd >/dev/null
    end
end
