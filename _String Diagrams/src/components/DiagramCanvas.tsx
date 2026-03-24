import React, { useMemo, useState, useCallback, useEffect, useRef } from 'react'
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
} from '@xyflow/react'
import type { Node, Edge, NodeChange } from '@xyflow/react'
import type { StringDiagram } from '../model/types'
import { layoutDiagram } from '../lib/layout'
import theme from '../lib/theme'
import MorphismNode from './MorphismNode'
import EndpointNode from './EndpointNode'
import OmegaNode from './OmegaNode'
import CopyDot from './CopyDot'
import NodeDetail from './NodeDetail'

const nodeTypes = {
  morphismBox: MorphismNode,
  endpoint: EndpointNode,
  omegaNode: OmegaNode,
  copyDot: CopyDot,
}

type MinimapMode = 'show' | 'hidden'

function IconMinimap() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="1" y="1" width="12" height="12" rx="2" />
      <rect x="7.5" y="7.5" width="5" height="5" rx="1" fill="currentColor" opacity="0.4" />
    </svg>
  )
}

function IconMinimapOff() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="1" y="1" width="12" height="12" rx="2" />
      <line x1="2" y1="12" x2="12" y2="2" />
    </svg>
  )
}

function IconParams() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="7" cy="4.5" r="3" />
      <line x1="7" y1="7.5" x2="7" y2="13" />
    </svg>
  )
}

function IconParamsOff() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="7" cy="4.5" r="3" />
      <line x1="7" y1="7.5" x2="7" y2="13" />
      <line x1="2" y1="12" x2="12" y2="2" />
    </svg>
  )
}

// --- localStorage persistence for node positions ---
const STORAGE_KEY = 'sd-node-positions'

function loadPositions(diagramId: string): Record<string, { x: number; y: number }> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return {}
    const all = JSON.parse(raw)
    return all[diagramId] ?? {}
  } catch {
    return {}
  }
}

function savePositions(diagramId: string, nodes: Node[]) {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    const all = raw ? JSON.parse(raw) : {}
    const positions: Record<string, { x: number; y: number }> = {}
    for (const n of nodes) {
      positions[n.id] = n.position
    }
    all[diagramId] = positions
    localStorage.setItem(STORAGE_KEY, JSON.stringify(all))
  } catch {
    // ignore
  }
}

function applyStoredPositions(nodes: Node[], diagramId: string): Node[] {
  const stored = loadPositions(diagramId)
  if (Object.keys(stored).length === 0) return nodes
  return nodes.map((n) => {
    const pos = stored[n.id]
    return pos ? { ...n, position: pos } : n
  })
}

interface SelectedMorphism {
  label: string
  haskellSig: string
  haskellDef: string
  mode: string
}

interface Props {
  diagram: StringDiagram
  sidebarWidth: number
}

export default function DiagramCanvas({ diagram, sidebarWidth }: Props) {
  const [minimapMode, setMinimapMode] = useState<MinimapMode>('show')
  const [showParams, setShowParams] = useState(true)
  const [selectedNode, setSelectedNode] = useState<SelectedMorphism | null>(null)

  const layout = useMemo(() => layoutDiagram(diagram), [diagram])

  // Identify parameter node/edge IDs
  const paramInfo = useMemo(() => {
    const topInputIds = new Set(
      diagram.inputs.filter((i) => i.side === 'top').map((i) => i.id)
    )
    const paramTargetPorts = new Set<string>()
    for (const m of diagram.morphisms) {
      for (const p of (m.paramInputs ?? [])) {
        paramTargetPorts.add(p.id)
      }
    }
    const isParamEdge = (e: Edge) =>
      topInputIds.has(e.source) || paramTargetPorts.has(e.targetHandle ?? '')

    const paramEdgeIds = new Set(layout.edges.filter(isParamEdge).map((e) => e.id))

    const greyParamEdges = layout.edges
      .filter(isParamEdge)
      .map((e) => ({
        ...e,
        style: { ...e.style, stroke: 'rgba(255,255,255,0.15)', strokeDasharray: '4 4' },
        animated: false,
        label: undefined,
      }))

    return { topInputIds, paramEdgeIds, greyParamEdges }
  }, [layout, diagram])

  // Apply stored positions on initial load
  const initialNodes = useMemo(
    () => applyStoredPositions(layout.nodes, diagram.id),
    [layout.nodes, diagram.id],
  )

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(layout.edges)

  // Save positions on every drag (debounced via node changes)
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const handleNodesChange = useCallback(
    (changes: NodeChange[]) => {
      onNodesChange(changes)

      const hasPositionChange = changes.some((c) => c.type === 'position')
      if (hasPositionChange) {
        // Sync anchor nodes to follow their fan-out copy dots
        setNodes((current) => {
          const posMap = new Map(current.map((n) => [n.id, n.position]))
          let changed = false
          const updated = current.map((n) => {
            if (n.id.startsWith('anchor-')) {
              // Find the corresponding fanout node
              const inputId = n.id.replace('anchor-', '')
              // Find fanout node that has this input as source
              const fanOutNode = current.find((fn) =>
                fn.id.startsWith('fanout-') && fn.id.includes(inputId)
              )
              if (fanOutNode) {
                const targetX = fanOutNode.position.x - 120
                const targetY = fanOutNode.position.y
                if (n.position.x !== targetX || n.position.y !== targetY) {
                  changed = true
                  return { ...n, position: { x: targetX, y: targetY } }
                }
              }
            }
            return n
          })

          // Debounced save
          if (saveTimerRef.current) clearTimeout(saveTimerRef.current)
          saveTimerRef.current = setTimeout(() => {
            setNodes((cur) => {
              savePositions(diagram.id, cur)
              return cur
            })
          }, 300)

          return changed ? updated : current
        })
      }
    },
    [onNodesChange, diagram.id, setNodes],
  )

  // Reset when diagram changes (new diagram selected)
  const prevDiagramId = useRef(diagram.id)
  useEffect(() => {
    if (prevDiagramId.current !== diagram.id) {
      prevDiagramId.current = diagram.id
      const restored = applyStoredPositions(layout.nodes, diagram.id)
      setNodes(restored)
      setEdges(layout.edges)
    }
  }, [diagram.id, layout, setNodes, setEdges])

  // Toggle params: only add/remove param nodes and edges, preserve positions
  useEffect(() => {
    setNodes((currentNodes) => {
      if (showParams) {
        const currentIds = new Set(currentNodes.map((n) => n.id))
        // Restore param nodes from stored positions if available, else layout
        const stored = loadPositions(diagram.id)
        const paramNodesToAdd = layout.nodes
          .filter((n) => paramInfo.topInputIds.has(n.id) && !currentIds.has(n.id))
          .map((n) => {
            const pos = stored[n.id]
            return pos ? { ...n, position: pos } : n
          })
        return [...currentNodes, ...paramNodesToAdd]
      } else {
        return currentNodes.filter((n) => !paramInfo.topInputIds.has(n.id))
      }
    })

    setEdges(() => {
      if (showParams) {
        const nonParamEdges = layout.edges.filter((e) => !paramInfo.paramEdgeIds.has(e.id))
        return [...nonParamEdges, ...paramInfo.greyParamEdges]
      } else {
        return layout.edges.filter((e) => !paramInfo.paramEdgeIds.has(e.id))
      }
    })
  }, [showParams, layout, paramInfo, setNodes, setEdges, diagram.id])

  const onNodeClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      const data = node.data as Record<string, unknown>
      if (data.haskellSig) {
        setSelectedNode({
          label: data.label as string,
          haskellSig: data.haskellSig as string,
          haskellDef: data.haskellDef as string,
          mode: data.mode as string,
        })
      }
    },
    [],
  )

  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        // @ts-expect-error CSS custom property
        '--controls-left': `${sidebarWidth + 12}px`,
      }}
    >
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={handleNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick}
        nodeTypes={nodeTypes}
        nodesDraggable={true}
        nodesConnectable={false}
        fitView
        fitViewOptions={{ padding: 0.3 }}
        minZoom={0.1}
        maxZoom={2}
        proOptions={{ hideAttribution: true }}
      >
        <Background color={theme.canvas.gridColor} gap={20} />
        <Controls />
        {minimapMode === 'show' && (
          <MiniMap
            nodeColor={(node: Node) => {
              const m = (node.data as Record<string, unknown>)?.mode as string | undefined
              if (m === 'kleisli') return `rgba(${theme.node.accentPurple},0.8)`
              return `rgba(${theme.node.accentBlue},0.8)`
            }}
            maskColor="rgba(0,0,0,0.25)"
            nodeStrokeWidth={0}
            pannable
            zoomable
          />
        )}
      </ReactFlow>

      {/* Toolbar */}
      <div
        style={{
          position: 'absolute',
          top: 12,
          left: `var(--controls-left, 12px)`,
          zIndex: 20,
          transition: 'left 0.25s ease',
          display: 'flex',
          gap: 6,
        }}
      >
        <div className="sd-toolbar-group">
          <button
            className="sd-toolbar-btn"
            title={minimapMode === 'show' ? 'Hide minimap' : 'Show minimap'}
            onClick={() => setMinimapMode((m) => m === 'show' ? 'hidden' : 'show')}
            style={{ color: minimapMode === 'show' ? theme.text.primary : theme.text.dimmed }}
          >
            {minimapMode === 'show' ? <IconMinimap /> : <IconMinimapOff />}
          </button>
        </div>

        <div className="sd-toolbar-group">
          <button
            className="sd-toolbar-btn"
            title={showParams ? 'Hide parameters' : 'Show parameters'}
            onClick={() => setShowParams((v) => !v)}
            style={{ color: showParams ? theme.text.primary : theme.text.dimmed }}
          >
            {showParams ? <IconParams /> : <IconParamsOff />}
          </button>
        </div>
      </div>

      {selectedNode && (
        <NodeDetail
          label={selectedNode.label}
          haskellSig={selectedNode.haskellSig}
          haskellDef={selectedNode.haskellDef}
          mode={selectedNode.mode}
          onClose={() => setSelectedNode(null)}
        />
      )}
    </div>
  )
}
