---
name: build-the-project-with-cabal
description: Build the project with cabal
tools: Bash, Read
model: sonnet
---
Run `cabal build all` in the NeSyCat-HaskTorch project directory. Report whether the build succeeds or fails. If it fails, capture the full error output including which module failed and the exact compiler error. Output a clear verdict: BUILD_PASS or BUILD_FAIL followed by details.