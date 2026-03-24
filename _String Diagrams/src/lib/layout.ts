import dagre from '@dagrejs/dagre'
import type { Node, Edge } from '@xyflow/react'
import type { StringDiagram } from '../model/types'
import theme from './theme'

const MORPH_WIDTH = 130
const MORPH_HEIGHT = 56
const COPY_SIZE = 16
const ENDPOINT_WIDTH = 90
const ENDPOINT_HEIGHT = 32

function accentForCategory(category: string): string {
  switch (category) {
    case 'pure': return theme.node.accentBlue
    case 'kleisli': return theme.node.accentPurple
    case 'logic': return theme.node.accentIndigo
    default: return theme.node.accentBlue
  }
}

function wireColor(wireType: string, isMonadic: boolean): string {
  if (isMonadic) return `rgba(${theme.node.accentPurple}, 0.5)`
  if (wireType === 'ParamsLogic' || wireType === 'ParamsMLP') {
    return `rgba(${theme.node.accentIndigo}, 0.35)`
  }
  return `rgba(${theme.node.accentBlue}, 0.5)`
}

function wireStrokeDasharray(wireType: string, isMonadic: boolean): string | undefined {
  if (isMonadic) return '8 4'
  if (wireType === 'ParamsLogic' || wireType === 'ParamsMLP') return '4 4'
  return undefined
}

export function layoutDiagram(diagram: StringDiagram): { nodes: Node[]; edges: Edge[] } {
  const g = new dagre.graphlib.Graph()
  g.setDefaultEdgeLabel(() => ({}))
  g.setGraph({
    rankdir: 'LR',
    ranksep: 150,
    nodesep: 50,
    marginx: 40,
    marginy: 40,
  })

  // Add input endpoint nodes
  for (const inp of diagram.inputs) {
    g.setNode(inp.id, { width: ENDPOINT_WIDTH, height: ENDPOINT_HEIGHT })
  }

  // Add output endpoint nodes
  for (const out of diagram.outputs) {
    g.setNode(out.id, { width: ENDPOINT_WIDTH, height: ENDPOINT_HEIGHT })
  }

  // Add morphism nodes
  for (const m of diagram.morphisms) {
    g.setNode(m.id, { width: MORPH_WIDTH, height: MORPH_HEIGHT })
  }

  // Add copy nodes
  for (const c of diagram.copies) {
    g.setNode(c.id, { width: COPY_SIZE, height: COPY_SIZE })
  }

  // Add edges for dagre layout
  for (const w of diagram.wires) {
    g.setEdge(w.sourceBox, w.targetBox)
  }

  dagre.layout(g)

  const nodes: Node[] = []

  // Input endpoints
  for (const inp of diagram.inputs) {
    const pos = g.node(inp.id)
    nodes.push({
      id: inp.id,
      type: 'endpoint',
      position: { x: pos.x - ENDPOINT_WIDTH / 2, y: pos.y - ENDPOINT_HEIGHT / 2 },
      data: { label: inp.label, wireType: inp.wireType, side: 'input' },
    })
  }

  // Output endpoints
  for (const out of diagram.outputs) {
    const pos = g.node(out.id)
    nodes.push({
      id: out.id,
      type: 'endpoint',
      position: { x: pos.x - ENDPOINT_WIDTH / 2, y: pos.y - ENDPOINT_HEIGHT / 2 },
      data: { label: out.label, wireType: out.wireType, side: 'output' },
    })
  }

  // Morphism nodes
  for (const m of diagram.morphisms) {
    const pos = g.node(m.id)
    nodes.push({
      id: m.id,
      type: 'morphismBox',
      position: { x: pos.x - MORPH_WIDTH / 2, y: pos.y - MORPH_HEIGHT / 2 },
      data: {
        label: m.label,
        haskellSig: m.haskellSig,
        category: m.category,
        accent: accentForCategory(m.category),
        inputs: m.inputs,
        outputs: m.outputs,
      },
    })
  }

  // Copy nodes
  for (const c of diagram.copies) {
    const pos = g.node(c.id)
    nodes.push({
      id: c.id,
      type: 'copyPoint',
      position: { x: pos.x - COPY_SIZE / 2, y: pos.y - COPY_SIZE / 2 },
      data: {
        wireType: c.wireType,
        input: c.input,
        outputs: c.outputs,
      },
    })
  }

  // Edges
  const edges: Edge[] = diagram.wires.map((w) => ({
    id: w.id,
    source: w.sourceBox,
    target: w.targetBox,
    sourceHandle: w.sourcePort,
    targetHandle: w.targetPort,
    type: 'smoothstep',
    animated: w.isMonadic,
    style: {
      stroke: wireColor(w.wireType, w.isMonadic),
      strokeWidth: w.isMonadic ? 2.5 : 2,
      strokeDasharray: wireStrokeDasharray(w.wireType, w.isMonadic),
    },
    label: w.wireType,
    labelStyle: {
      fill: theme.text.dimmed,
      fontSize: 10,
      fontFamily: 'inherit',
    },
    labelBgStyle: {
      fill: theme.canvas.background,
      fillOpacity: 0.8,
    },
  }))

  return { nodes, edges }
}
