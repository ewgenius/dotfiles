# Create git worktree and open in Zed
# Usage: wz <worktree-name>
function wz
    if test (count $argv) -eq 0
        echo "Usage: wz <worktree-name>"
        return 1
    end

    set -l abs_path (w $argv[1])
    or return 1

    echo "Opening Zed at '$abs_path'..."
    zed "$abs_path"
end
