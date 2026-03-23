---
name: write-current-issues-to-claudeissuesmd
description: Write current issues to .claude/ISSUES.md
tools: Write, Read
model: sonnet
---
Write the issue registry from the verification report to `.claude/ISSUES.md`.

The file should contain the FULL verification report's Issue Registry, structured as:

```markdown
# Current Issues

_Last verified: {today's date}_

## BLOCKING
{list all blocking issues, or "None"}

## BUG
{list all bug issues with details}

## DEBT
{list all debt issues}

## INFO
{list all info items}
```

Rules:
- **Overwrite** the file completely each time — this is a snapshot, not a log
- Include enough detail for each issue that someone reading it later understands what's wrong and where
- Include the experiment scores/times table so regressions can be spotted across runs
- The file path is `/Users/cherryfunk/Repos/NeSyCat-HaskTorch/.claude/ISSUES.md`