---
name: analyze-build-failure-and-suggest-fixes
description: Analyze build failure and suggest fixes
tools: Bash, Read, Glob, Grep
model: sonnet
---
The cabal build failed. Analyze the build error from the previous step.

1. Identify the exact module and line causing the failure
2. Read the failing source file to understand the context
3. Diagnose the root cause (type error, missing import, missing instance, etc.)
4. Suggest a concrete fix

Output a clear report with: failing module, error type, root cause, and suggested fix.