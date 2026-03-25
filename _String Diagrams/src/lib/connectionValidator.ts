import type { StringDiagram } from '../model/types'

interface ValidationResult {
  valid: boolean
  reason?: string
  wireType: string
}

export function validateConnection(
  sourceNodeId: string,
  sourceHandleId: string,
  targetNodeId: string,
  targetHandleId: string,
  diagram: StringDiagram,
): ValidationResult {
  // No self-connections
  if (sourceNodeId === targetNodeId) {
    return { valid: false, reason: 'Cannot connect a node to itself', wireType: '' }
  }

  // No duplicate wires
  const duplicate = diagram.wires.some(
    (w) => w.sourceBox === sourceNodeId && w.sourcePort === sourceHandleId
      && w.targetBox === targetNodeId && w.targetPort === targetHandleId
  )
  if (duplicate) {
    return { valid: false, reason: 'Wire already exists', wireType: '' }
  }

  // Resolve source port type for the wire label
  const sourceType = resolvePortType(sourceNodeId, sourceHandleId, 'source', diagram)

  return { valid: true, wireType: sourceType || 'Omega U' }
}

function resolvePortType(
  nodeId: string,
  handleId: string,
  direction: 'source' | 'target',
  diagram: StringDiagram,
): string | null {
  const morph = diagram.morphisms.find((m) => m.id === nodeId)
  if (morph) {
    if (direction === 'source') {
      const port = morph.outputs.find((p) => p.id === handleId)
      if (port) return port.label
    } else {
      const port = morph.inputs.find((p) => p.id === handleId)
        || morph.paramInputs?.find((p) => p.id === handleId)
      if (port) return port.label
    }
  }

  const inp = diagram.inputs.find((i) => i.id === nodeId)
  if (inp) return inp.wireType

  const out = diagram.outputs.find((o) => o.id === nodeId)
  if (out) return out.wireType

  return null
}
