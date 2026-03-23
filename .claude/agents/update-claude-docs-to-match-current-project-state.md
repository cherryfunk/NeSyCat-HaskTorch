---
name: update-claude-docs-to-match-current-project-state
description: Update .claude/ docs to match current project state
tools: Bash, Read, Write, Edit, Glob, Grep
model: opus
---
Update the .claude/ documentation to accurately reflect the current state of the NeSyCat-HaskTorch project. You have the verification report from the previous steps as context.

Do the following:

1. **Read** the current `.claude/CLAUDE.md`
2. **Scan** the actual project structure (directories, .cabal file, source files) to determine:
   - Which executables actually exist and are runnable
   - Which layers and domains currently exist
   - Which logical interpretations are present
   - The actual sub-pipeline naming convention (A_Category, B_Theory, BA_Interpretation, BC_Extension, C_TypeSystem, D_Vocabulary, DA_Realization) — NOT the idealized A-G names
3. **Update CLAUDE.md** to match reality:
   - Fix the Build & Run Commands section (only list executables that exist in the .cabal file)
   - Fix the Architecture section (only list layers/domains that actually exist)
   - Fix any references to removed modules or outdated structure
   - Keep the document concise and accurate
4. **Check each agent file** in `.claude/agents/` — update any that reference domains, modules, or structures that no longer exist

IMPORTANT: Only update what is factually wrong. Do not rewrite working descriptions, add unnecessary detail, or change the document's style. Preserve the author's voice and structure.