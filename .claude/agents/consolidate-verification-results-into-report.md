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
- Any regressions or failures noted

### 3. Layer Consistency
- ABCDEFG coverage per layer
- Missing connections or gaps

### Overall Verdict
- ALL_CLEAR if everything passes
- ISSUES_FOUND with a prioritized list of what needs attention

Be concise but complete. This report should give the developer a quick yes/no on whether the project is healthy, with details only where something needs fixing.