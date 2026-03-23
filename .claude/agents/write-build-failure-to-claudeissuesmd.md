---
name: write-build-failure-to-claudeissuesmd
description: Write build failure to .claude/ISSUES.md
tools: Write, Read
model: sonnet
---
Write the build failure details to `.claude/ISSUES.md`.

The file should contain:

```markdown
# Current Issues

_Last verified: {today's date}_

## BLOCKING
- **Build failure**: {include the full error details from the build failure analysis — module, error type, root cause, suggested fix}

## BUG
None (build failed, experiments not run)

## DEBT
None (build failed, layer check not run)

## INFO
- Build must be fixed before any other verification can proceed
```

Rules:
- **Overwrite** the file completely each time
- The file path is `/Users/cherryfunk/Repos/NeSyCat-HaskTorch/.claude/ISSUES.md`