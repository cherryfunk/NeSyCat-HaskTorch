import dagre from '@dagrejs/dagre'
import type { Node, Edge } from '@xyflow/react'
import type { StringDiagram } from '../model/types'
import theme from './theme'

const MORPH_WIDTH = 130
const MORPH_HEIGHT = 44
const OMEGA_SIZE = 28
const COPY_SIZE = 10
const ENDPOINT_WIDTH = 90
const ENDPOINT_HEIGHT = 32
const PARAM_Y_OFFSET = 40

function accentForMode(mode: string): string {
  if (mode === 'kleisli') return theme.node.accentPurple
  return theme.node.accentBlue
}

interface FanOutNode {
  id: string
  sourceBox: string
  sourcePort: string
  wireType: string
  wires: { id: string; sourceBox: string; sourcePort: string; targetBox: string; targetPort: string; wireType: string; isMonadic: boolean }[]
  isOmega: boolean
}

export function layoutDiagram(diagram: StringDiagram): { nodes: Node[]; edges: Edge[] } {
  // Identify parameter ports and top inputs
  const paramTargetPorts = new Set<string>()
  for (const m of diagram.morphisms) {
    for (const p of (m.paramInputs ?? [])) {
      paramTargetPorts.add(p.id)
    }
  }
  const topInputs = diagram.inputs.filter((i) => i.side === 'top')
  const topInputIds = new Set(topInputs.map((i) => i.id))
  const leftInputIds = new Set(diagram.inputs.filter((i) => i.side !== 'top').map((i) => i.id))
  const outputIds = new Set(diagram.outputs.map((o) => o.id))

  // Build mode map
  const morphModeMap = new Map<string, string>()
  for (const m of diagram.morphisms) {
    morphModeMap.set(m.id, m.mode)
  }

  // Find output ports that fan out to multiple targets (excluding param wires)
  const fanOutMap = new Map<string, typeof diagram.wires>()
  for (const w of diagram.wires) {
    if (paramTargetPorts.has(w.targetPort)) continue
    if (topInputIds.has(w.sourceBox)) continue
    const key = `${w.sourceBox}::${w.sourcePort}`
    const arr = fanOutMap.get(key) ?? []
    arr.push(w)
    fanOutMap.set(key, arr)
  }

  // Create fan-out nodes
  const fanOutNodes: FanOutNode[] = []
  for (const [key, wires] of fanOutMap) {
    if (wires.length >= 2) {
      const [sourceBox, sourcePort] = key.split('::')
      const wt = wires[0].wireType
      const isOmega = wt === 'Omega' || wt === 'M(Omega)'
      const id = `fanout-${sourceBox}-${sourcePort}`
      fanOutNodes.push({ id, sourceBox, sourcePort, wireType: wt, wires, isOmega })
    }
  }
  const fanOutByKey = new Map(fanOutNodes.map((f) => [`${f.sourceBox}::${f.sourcePort}`, f]))

  // Build dagre graph -- NO endpoint nodes for left inputs or outputs
  const g = new dagre.graphlib.Graph()
  g.setDefaultEdgeLabel(() => ({}))
  g.setGraph({ rankdir: 'LR', ranksep: 120, nodesep: 50, marginx: 40, marginy: 40 })

  for (const m of diagram.morphisms) {
    g.setNode(m.id, { width: MORPH_WIDTH, height: MORPH_HEIGHT })
  }
  for (const f of fanOutNodes) {
    const size = OMEGA_SIZE
    g.setNode(f.id, { width: size, height: size })
  }

  // Add edges for dagre (skip wires to/from endpoints -- they don't exist as nodes)
  const seenEdges = new Set<string>()
  for (const w of diagram.wires) {
    if (paramTargetPorts.has(w.targetPort)) continue
    if (topInputIds.has(w.sourceBox)) continue
    // Skip wires from left inputs or to outputs (those nodes don't exist in dagre)
    if (leftInputIds.has(w.sourceBox)) continue
    if (outputIds.has(w.targetBox)) continue

    const key = `${w.sourceBox}::${w.sourcePort}`
    const fanOut = fanOutByKey.get(key)

    if (fanOut) {
      const eKey1 = `${w.sourceBox}->${fanOut.id}`
      if (!seenEdges.has(eKey1)) {
        seenEdges.add(eKey1)
        g.setEdge(w.sourceBox, fanOut.id)
      }
      const eKey2 = `${fanOut.id}->${w.targetBox}`
      if (!seenEdges.has(eKey2)) {
        seenEdges.add(eKey2)
        g.setEdge(fanOut.id, w.targetBox)
      }
    } else {
      const eKey = `${w.sourceBox}->${w.targetBox}`
      if (!seenEdges.has(eKey)) {
        seenEdges.add(eKey)
        g.setEdge(w.sourceBox, w.targetBox)
      }
    }
  }

  // For left input fan-outs, we need the fan-out node in dagre connected to its targets
  for (const f of fanOutNodes) {
    if (leftInputIds.has(f.sourceBox)) {
      for (const w of f.wires) {
        const eKey = `${f.id}->${w.targetBox}`
        if (!seenEdges.has(eKey)) {
          seenEdges.add(eKey)
          g.setEdge(f.id, w.targetBox)
        }
      }
    }
  }

  dagre.layout(g)

  const nodes: Node[] = []

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
        haskellClass: m.haskellClass,
        instances: m.instances,
        mode: m.mode,
        accent: accentForMode(m.mode),
        inputs: m.inputs,
        outputs: m.outputs,
        paramInputs: m.paramInputs ?? [],
      },
    })
  }

  // Fan-out nodes
  const inputAnchorEdges: { anchorId: string; fanOutId: string; label: string; accent: string }[] = []
  for (const f of fanOutNodes) {
    const pos = g.node(f.id)
    const sourceMode = morphModeMap.get(f.sourceBox) ?? 'tarski'
    const accent = accentForMode(sourceMode)

    if (f.isOmega) {
      const isM = f.wireType === 'M(Omega)' || f.wireType.startsWith('M(')
      const label = isM ? 'M(\u03A9)' : '\u03A9'
      nodes.push({
        id: f.id,
        type: 'omegaNode',
        position: { x: pos.x - OMEGA_SIZE / 2, y: pos.y - OMEGA_SIZE / 2 },
        data: { label, accent, outputCount: f.wires.length },
      })
    } else {
      nodes.push({
        id: f.id,
        type: 'copyDot',
        position: { x: pos.x - OMEGA_SIZE / 2, y: pos.y - OMEGA_SIZE / 2 },
        data: { accent, outputCount: f.wires.length },
      })

      // For left-input fan-outs, add an invisible anchor node + real edge with label
      if (leftInputIds.has(f.sourceBox)) {
        const anchorId = `anchor-${f.sourceBox}`
        const inp = diagram.inputs.find((i) => i.id === f.sourceBox)
        nodes.push({
          id: anchorId,
          type: 'copyDot',
          position: { x: pos.x - OMEGA_SIZE / 2 - 120, y: pos.y - OMEGA_SIZE / 2 },
          data: { accent, outputCount: 1 },
          style: { opacity: 0 },
        })
        // Store anchor info so we can link it to the copy dot in edges
        inputAnchorEdges.push({
          anchorId,
          fanOutId: f.id,
          label: inp?.label ?? '',
          accent,
        })
      }
    }
  }

  // Top parameter inputs -- positioned above targets
  for (const inp of topInputs) {
    const targetMorphIds = diagram.wires
      .filter((w) => w.sourceBox === inp.id)
      .map((w) => w.targetBox)
    const targetPositions = targetMorphIds.map((id) => g.node(id)).filter(Boolean)

    if (targetPositions.length > 0) {
      const avgX = targetPositions.reduce((s, p) => s + p.x, 0) / targetPositions.length
      const minY = Math.min(...targetPositions.map((p) => p.y))
      nodes.push({
        id: inp.id,
        type: 'endpoint',
        position: { x: avgX - ENDPOINT_WIDTH / 2, y: minY - MORPH_HEIGHT / 2 - PARAM_Y_OFFSET },
        data: { label: inp.label, wireType: inp.wireType, side: 'input', inputSide: 'top' },
      })
    }
  }

  // Build edges -- skip wires that go to/from removed endpoint nodes
  const edges: Edge[] = []

  for (const w of diagram.wires) {
    const isParam = paramTargetPorts.has(w.targetPort) || topInputIds.has(w.sourceBox)

    // Wires from left inputs go through fan-out copy dots
    if (leftInputIds.has(w.sourceBox)) {
      const key = `${w.sourceBox}::${w.sourcePort}`
      const fanOut = fanOutByKey.get(key)
      if (fanOut) {
        const wireIndex = fanOut.wires.indexOf(w)
        const edgeColor = `rgba(${theme.node.accentBlue}, 0.5)`
        edges.push({
          id: w.id,
          source: fanOut.id,
          target: w.targetBox,
          sourceHandle: `out-${wireIndex}`,
          targetHandle: w.targetPort,
          type: 'smoothstep',
          animated: true,
          style: { stroke: edgeColor, strokeWidth: 2 },
        })
      }
      continue
    }

    // Skip wires to output endpoints (no target node)
    if (outputIds.has(w.targetBox)) {
      // Wire just ends at the morphism output -- no target node
      continue
    }

    const sourceMode = morphModeMap.get(w.sourceBox)
    const isKleisli = sourceMode === 'kleisli'
    const edgeColor = isParam
      ? `rgba(${theme.node.accentIndigo}, 0.35)`
      : isKleisli
        ? `rgba(${theme.node.accentPurple}, 0.5)`
        : `rgba(${theme.node.accentBlue}, 0.5)`

    const key = `${w.sourceBox}::${w.sourcePort}`
    const fanOut = fanOutByKey.get(key)

    if (fanOut && !isParam) {
      const wireIndex = fanOut.wires.indexOf(w)

      if (wireIndex === 0) {
        edges.push({
          id: `${w.id}-to-fanout`,
          source: w.sourceBox,
          target: fanOut.id,
          sourceHandle: w.sourcePort,
          targetHandle: 'in',
          type: 'smoothstep',
          animated: true,
          style: { stroke: edgeColor, strokeWidth: 2 },
        })
      }

      edges.push({
        id: w.id,
        source: fanOut.id,
        target: w.targetBox,
        sourceHandle: `out-${wireIndex}`,
        targetHandle: w.targetPort,
        type: 'smoothstep',
        animated: true,
        style: { stroke: edgeColor, strokeWidth: 2 },
      })
    } else {
      edges.push({
        id: w.id,
        source: w.sourceBox,
        target: w.targetBox,
        sourceHandle: w.sourcePort,
        targetHandle: w.targetPort,
        type: 'smoothstep',
        animated: !isParam,
        style: {
          stroke: edgeColor,
          strokeWidth: isParam ? 1.5 : 2,
          strokeDasharray: isParam ? '4 4' : undefined,
        },
      })
    }
  }

  // Add labeled stub edges from invisible anchors to copy dots
  for (const a of inputAnchorEdges) {
    edges.push({
      id: `stub-${a.anchorId}`,
      source: a.anchorId,
      target: a.fanOutId,
      sourceHandle: 'out-0',
      targetHandle: 'in',
      type: 'straight',
      animated: true,
      style: { stroke: `rgba(${a.accent}, 0.5)`, strokeWidth: 2 },
      label: a.label,
      labelStyle: {
        fill: theme.text.muted,
        fontSize: 11,
        fontFamily: 'inherit',
      },
      labelBgStyle: {
        fill: theme.canvas.background,
        fillOpacity: 0.8,
      },
    })
  }

  return { nodes, edges }
}
