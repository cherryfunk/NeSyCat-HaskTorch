import dagre from '@dagrejs/dagre'
import type { Node, Edge } from '@xyflow/react'
import type { StringDiagram } from '../model/types'
import theme from './theme'

const MORPH_WIDTH = 130
const MORPH_HEIGHT = 44
const OMEGA_SIZE = 28
const WALL_X = 50
const VAR_SPACING = 40
const VAR_NODE_WIDTH = 70 // 8 + 50 + 12 padding

function accentForMode(mode: string): string {
  if (mode === 'kleisli') return theme.node.accentPurple
  return theme.node.accentBlue
}

// Single function: StringDiagram -> { nodes, edges }
// Both view and edit mode use this. No other source.
export function buildReactFlowGraph(diagram: StringDiagram): { nodes: Node[]; edges: Edge[] } {
  const nodes: Node[] = []
  const edges: Edge[] = []

  // --- 1. Morphism nodes (use dagre for layout) ---
  const g = new dagre.graphlib.Graph()
  g.setDefaultEdgeLabel(() => ({}))
  g.setGraph({ rankdir: 'LR', ranksep: 120, nodesep: 50, marginx: 250, marginy: 40 })

  for (const m of diagram.morphisms) {
    const maxPorts = Math.max(m.inputs.length, m.outputs.length, 1)
    const h = Math.max(MORPH_HEIGHT, maxPorts * 20 + 16)
    g.setNode(m.id, { width: MORPH_WIDTH, height: h })
  }

  // Add morph-to-morph edges for dagre layout (skip variable/param wires)
  const leftInputIds = new Set(diagram.inputs.filter((i) => i.side === 'left').map((i) => i.id))
  const topInputIds = new Set(diagram.inputs.filter((i) => i.side === 'top').map((i) => i.id))
  const seenDagreEdges = new Set<string>()
  for (const w of diagram.wires) {
    if (leftInputIds.has(w.sourceBox) || topInputIds.has(w.sourceBox)) continue
    const key = `${w.sourceBox}->${w.targetBox}`
    if (!seenDagreEdges.has(key) && g.hasNode(w.sourceBox) && g.hasNode(w.targetBox)) {
      seenDagreEdges.add(key)
      g.setEdge(w.sourceBox, w.targetBox)
    }
  }

  dagre.layout(g)

  for (const m of diagram.morphisms) {
    const pos = g.node(m.id)
    if (!pos) continue
    const maxPorts = Math.max(m.inputs.length, m.outputs.length, 1)
    const h = Math.max(MORPH_HEIGHT, maxPorts * 20 + 16)
    nodes.push({
      id: m.id,
      type: 'morphismBox',
      position: { x: pos.x - MORPH_WIDTH / 2, y: pos.y - h / 2 },
      data: {
        label: m.label,
        haskellSig: m.haskellSig,
        haskellClass: m.haskellClass,
        instances: m.instances,
        mode: m.mode,
        layer: m.layer,
        accent: accentForMode(m.mode),
        inputs: m.inputs,
        outputs: m.outputs,
        paramInputs: m.paramInputs ?? [],
      },
    })
  }

  // --- 2. Wall node ---
  const wallId = `wall-${diagram.id}`
  nodes.push({
    id: wallId,
    type: 'wallNode',
    position: { x: WALL_X, y: -200 },
    data: { height: 600 },
    draggable: true,
    selectable: false,
  })

  // --- 3. Variable nodes (left inputs) ---
  const leftInputs = diagram.inputs.filter((i) => i.side === 'left')
  for (let i = 0; i < leftInputs.length; i++) {
    const inp = leftInputs[i]
    nodes.push({
      id: inp.id,
      type: 'variableNode',
      position: { x: WALL_X - VAR_NODE_WIDTH + 1, y: -200 + 50 + i * VAR_SPACING },
      draggable: false,
      data: { label: inp.label },
    })
  }

  // --- 4. Parameter endpoint nodes (top inputs) ---
  const topInputs = diagram.inputs.filter((i) => i.side === 'top')
  for (const inp of topInputs) {
    // Position above the first morphism that uses this param
    const targetWire = diagram.wires.find((w) => w.sourceBox === inp.id)
    const targetPos = targetWire ? g.node(targetWire.targetBox) : null
    const x = targetPos ? targetPos.x - 45 : 300
    const y = targetPos ? targetPos.y - 80 : -100
    nodes.push({
      id: inp.id,
      type: 'endpoint',
      position: { x, y },
      data: { label: inp.label, wireType: inp.wireType, side: 'input', inputSide: 'top' },
    })
  }

  // --- 5. ALL edges from diagram.wires -- every wire is a visible edge ---
  for (const w of diagram.wires) {
    const label = w.wireType || '?'
    edges.push({
      id: w.id,
      source: w.sourceBox,
      target: w.targetBox,
      sourceHandle: w.sourcePort,
      targetHandle: w.targetPort,
      type: 'smoothstep',
      animated: true,
      label,
      labelStyle: { fill: theme.text.dimmed, fontSize: 10, fontFamily: 'inherit' },
      labelBgStyle: { fill: theme.canvas.background, fillOpacity: 0.8 },
      style: { stroke: `rgba(${theme.node.accentBlue}, 0.5)`, strokeWidth: 2 },
    })
  }

  return { nodes, edges }
}
