# Agent Instructions

Uses **Gyrus** for knowledge management and task tracking.

## Quick Reference

```bash
# Find and start work
gyrus task list --status todo        # See available tasks
gyrus task read <id>                 # View task details
gyrus task update <id> --status in-progress  # Claim work

# Create work items
gyrus adr create --title "Feature" --type enhancement  # Plan major work
gyrus task create --title "Task" --related-adrs <adr>  # Break down into tasks

# Complete work
gyrus task complete <id>             # Mark task done
gyrus adr update <name> --status completed  # Mark ADR done

# Knowledge management
gyrus knowledge search "topic"       # Find existing knowledge
gyrus knowledge create --id <id> --title "..." --category <cat>
```

## Spec-Driven Development Workflow

**For any significant work (>1 hour):**

1. **Create ADR first** - Define what & why

   ```bash
   gyrus adr create --title "User Authentication" --type enhancement --working-folder .
   ```

2. **Break into tasks** - Make work trackable

   ```bash
   gyrus task create --title "Implement OAuth" --priority high --related-adrs <adr-name>
   ```

3. **Track progress** - Update as you work

   ```bash
   gyrus task update <id> --status in-progress
   gyrus task complete <id>
   ```

4. **Capture knowledge** - Save lessons learned
   ```bash
   gyrus knowledge create --id pattern-oauth --title "OAuth Pattern" --category patterns
   ```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create ADRs/tasks for anything unfinished
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update work status** - Close finished tasks, update in-progress items
4. **Hand off** - Provide context for next session
