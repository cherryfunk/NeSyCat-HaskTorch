---
name: generate-fix-plan-from-issuesmd
description: Generate fix plan from ISSUES.md
tools: Read, Write, Glob, Grep
model: opus
---
Read `/Users/cherryfunk/Repos/NeSyCat-HaskTorch/.claude/ISSUES.md` and generate a concrete fix plan for every issue listed.

For each issue, analyze the relevant source code and produce:

### For BLOCKING issues:
- Exact error and root cause
- File(s) to modify with line numbers
- Proposed code change (show old → new)
- Priority: CRITICAL

### For BUG issues:
- Root cause analysis (read the relevant source files)
- File(s) to modify with line numbers
- Proposed fix (show old → new code)
- Impact assessment: what else might be affected
- Priority: HIGH

### For DEBT issues:
- For each orphaned/unused module, decide:
  - **DELETE** if truly dead code with no future purpose
  - **KEEP** if it's aspirational scaffolding for future domains/features (explain why)
  - **REFACTOR** if the code is valuable but needs to be connected
- For each decision, list the exact files and .cabal entries to change
- Priority: LOW

Write the plan to `/Users/cherryfunk/Repos/NeSyCat-HaskTorch/.claude/FIX_PLAN.md` with this structure:

```markdown
# Fix Plan

_Generated: {today's date}_
_Based on: .claude/ISSUES.md_

## Priority 1: BLOCKING
{fixes for blocking issues}

## Priority 2: BUG
{fixes for bug issues}

## Priority 3: DEBT
{fixes for debt issues, with DELETE/KEEP/REFACTOR decisions}

## Estimated Changes
- Files to modify: {count}
- Files to delete: {count}
- .cabal entries to update: {count}
```

Overwrite the file completely each time.