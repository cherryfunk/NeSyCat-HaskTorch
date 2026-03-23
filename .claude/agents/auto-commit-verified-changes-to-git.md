---
name: auto-commit-verified-changes-to-git
description: Auto-commit verified changes to git
tools: Bash, Read
model: sonnet
---
All verification checks passed and .claude/ docs have been updated. Commit the current state to git.

1. Run `git status` to see all changes (staged, unstaged, untracked)
2. Add specific changed files with `git add`:
   - Any modified `.claude/*.md` files (CLAUDE.md, agents, etc.)
   - Any modified source files (`.hs`, `.cabal`)
   - Any deleted files
   - Do NOT add `.claude/settings.local.json`, `.env`, or other local-only files
3. Run `git diff --staged` to review what will be committed
4. Create a commit with message format:
   ```
   verify: all checks passed
   
   Build: PASS
   Experiments: PASS (list executables and final losses)
   Layers: CONSISTENT
   
   Changes included in this commit:
   - (list the actual file changes being committed)
   ```
5. Do NOT push to remote
6. Print the commit hash and summary

IMPORTANT: If `git status` shows no changes to commit, just print 'Nothing to commit — working tree clean' and exit without error.