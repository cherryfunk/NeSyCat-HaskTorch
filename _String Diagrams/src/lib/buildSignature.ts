import type { StringDiagram } from '../model/types'

// Single source of truth: edges and their labels.
// Inputs = edges going INTO this node. Outputs = edges going OUT.
export function buildSignature(morphId: string, diagram: StringDiagram): string {
  const morph = diagram.morphisms.find((m) => m.id === morphId)
  if (!morph) return ''

  const inputLabels = diagram.wires
    .filter((w) => w.targetBox === morphId)
    .map((w) => w.wireType || '?')

  const outputLabels = diagram.wires
    .filter((w) => w.sourceBox === morphId)
    .map((w) => w.wireType || '?')

  const parts = [...inputLabels]
  if (outputLabels.length > 0) {
    const out = outputLabels[0]
    parts.push(morph.mode === 'kleisli' ? `M U (${out})` : out)
  } else {
    parts.push('?')
  }

  return `${morph.label} :: ${parts.join(' -> ')}`
}
