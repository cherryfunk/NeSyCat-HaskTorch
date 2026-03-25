import type { StringDiagram } from '../model/types'
import { generateTheory } from './generateTheory'
import { generateFormulas } from './generateFormulas'
import { generateInterpretations } from './generateInterpretation'

export interface GeneratedFile {
  path: string
  content: string
}

export function generateAllFiles(diagram: StringDiagram): GeneratedFile[] {
  const files: GeneratedFile[] = []

  // Domain theory (only if there are domain-layer morphisms)
  const theory = generateTheory(diagram)
  if (theory) files.push(theory)

  // Grammatical formula
  const formula = generateFormulas(diagram)
  files.push(formula)

  // Interpretations (MeasU + GeomU)
  const interps = generateInterpretations(diagram)
  files.push(...interps)

  return files
}
