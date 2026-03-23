---
name: generate-fix-plan-for-build-failure
description: Generate fix plan for build failure
tools: Read, Write, Glob, Grep
model: opus
---
Read `/Users/cherryfunk/Repos/NeSyCat-HaskTorch/.claude/ISSUES.md` and generate a concrete fix plan for the build failure.

Analyze the build error:
1. Read the failing source file(s)
2. Identify the exact root cause
3. Propose the minimal fix (show old → new code)
4. Check if the fix might affect other modules

Write the plan to `/Users/cherryfunk/Repos/NeSyCat-HaskTorch/.claude/FIX_PLAN.md` with this structure:

```markdown
# Fix Plan

_Generated: {today's date}_
_Based on: .claude/ISSUES.md_

## Priority 1: BLOCKING — Build Failure

### Root Cause
{analysis}

### Fix
**File**: {path}
**Change**:
```haskell
-- OLD:
{old code}
-- NEW:
{new code}
```

### Verification
`cabal build all` should succeed after this change.
```

Overwrite the file completely each time.