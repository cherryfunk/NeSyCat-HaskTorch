---
name: consolidate-verification-results-into-report
description: Consolidate verification results into report
tools: Bash, Read
model: sonnet
---
Consolidate all verification results from the previous steps into a clear summary report.

Structure the report as:

## NeSyCat-HaskTorch Verification Report

### 1. Build Status
- PASS/FAIL + details

### 2. Experiment Results
- Table of experiment scores and times
- **ALWAYS report every issue, even known ones.** NaN losses, divergences, numerical instabilities, missing eval blocks — list them ALL every time. A known bug is still a bug.
- Flag any regressions compared to expected behavior

### 3. Layer Consistency
- ABCDEFG coverage per layer
- Missing connections or gaps
- **ALWAYS list orphaned modules** (modules that exist but are never imported)
- **ALWAYS list placeholder-only modules** (modules with no real code)

### 4. Issue Registry
List EVERY issue found, categorized as:
- **BLOCKING**: Build failures, crashes, missing modules that break the pipeline
- **BUG**: NaN losses, numerical instabilities, divergences, incorrect results
- **DEBT**: Orphaned modules, unused code, placeholder files, stale references
- **INFO**: Observations that aren't issues but worth noting

### Overall Verdict
- **ALL_CLEAR**: ONLY if there are zero BLOCKING and zero BUG issues
- **ISSUES_FOUND**: If ANY blocking or bug issues exist, even "known" ones

A "known" bug is NOT the same as "acceptable". If JIT produces NaN, the verdict is ISSUES_FOUND. If orphaned modules exist, list them as DEBT. Never suppress or downplay findings — the whole point of this report is to surface problems, not hide them.