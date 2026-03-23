---
name: verify-abcdefg-layer-consistency
description: Verify ABCDEFG layer consistency
tools: Bash, Read, Glob, Grep
model: opus
---
Verify the ABCDEFG pipeline consistency of the NeSyCat-HaskTorch project. The project has layers A_Categorical, B_Logical, C_Domain, D_Grammatical, and within each layer modules follow the A→B→C→D→E→F→G sub-pipeline.

Check the following:

1. **Theory → Extension coverage**: For every type class declared in D_Theory modules, verify there is a corresponding E_Extension module with type family instances. List any theories without extensions.

2. **Vocabulary → Realization coverage**: For every vocabulary type defined in B_Vocabulary modules, verify there is a realization (interpretation) that connects it. List any vocabularies without realizations.

3. **Extension → Interpretation coverage**: For every E_Extension, verify there is a matching F_Interpretation module that provides concrete implementations. List any extensions without interpretations.

4. **Category connection**: Verify that A_Category modules (DATA, TENS GADTs) are referenced by the interpretations — i.e., the interpretations actually use the categorical witnesses.

5. **Domain completeness**: For each domain in C_Domain, check which sub-pipeline steps (A through G) exist. Do NOT hardcode domain names — discover them dynamically by scanning the actual directory structure.

Scan the actual source files using Glob and Grep. Report a structured summary:
- For each layer: which sub-steps exist, which are missing
- Any orphaned modules (exist but not connected)
- Overall verdict: LAYERS_CONSISTENT or LAYERS_INCONSISTENT with specific gaps listed.