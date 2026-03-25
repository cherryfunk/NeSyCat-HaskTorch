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

  return { valid: true, wireType: '' }
}
