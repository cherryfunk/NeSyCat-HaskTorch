import React, { useMemo, useState, useCallback, useEffect, useRef } from 'react'
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  useReactFlow,
} from '@xyflow/react'
import type { Node, Edge, NodeChange, Connection } from '@xyflow/react'
import type { StringDiagram } from '../model/types'
import { buildReactFlowGraph } from '../lib/buildGraph'
import { validateConnection } from '../lib/connectionValidator'
import { buildSignature } from '../lib/buildSignature'
import theme from '../lib/theme'
import { useDiagramStore } from '../store/diagramStore'
import MorphismNode from './MorphismNode'
import EndpointNode from './EndpointNode'
import CopyDot from './CopyDot'
import VariableNode from './VariableNode'
import WallNode from './WallNode'
import NodeDetail from './NodeDetail'
import EditorToolbar from './editor/EditorToolbar'
import NodeEditor from './editor/NodeEditor'

const nodeTypes = {
  morphismBox: MorphismNode,
  endpoint: EndpointNode,
  copyDot: CopyDot,
  variableNode: VariableNode,
  wallNode: WallNode,
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
const POS_KEY = 'sd-node-positions'

function loadPositions(diagramId: string): Record<string, { x: number; y: number }> {
  try {
    const raw = localStorage.getItem(POS_KEY)
    if (!raw) return {}
    return (JSON.parse(raw))[diagramId] ?? {}
  } catch { return {} }
}

function savePositions(diagramId: string, nodes: Node[]) {
  try {
    const raw = localStorage.getItem(POS_KEY)
    const all = raw ? JSON.parse(raw) : {}
    const positions: Record<string, { x: number; y: number }> = {}
    for (const n of nodes) positions[n.id] = n.position
    all[diagramId] = positions
    localStorage.setItem(POS_KEY, JSON.stringify(all))
  } catch { /* ignore */ }
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
  id: string
  label: string
  haskellSig: string
  haskellClass: string
  instances: { universe: string; def: string }[]
  mode: string
}

interface Props {
  diagram: StringDiagram
  sidebarWidth: number
}

export default function DiagramCanvas({ diagram, sidebarWidth }: Props) {
  const storeMode = useDiagramStore((s) => s.mode)
  const addWire = useDiagramStore((s) => s.addWire)
  const setSelectedNode = useDiagramStore((s) => s.setSelectedNode)
  const selectedNodeId = useDiagramStore((s) => s.selectedNodeId)
  const addMorphismAtPosition = useDiagramStore((s) => s.addMorphismAtPosition)
  const renamePort = useDiagramStore((s) => s.renamePort)
  const renameWire = useDiagramStore((s) => s.renameWire)
  const removeMorphism = useDiagramStore((s) => s.removeMorphism)
  const removeWire = useDiagramStore((s) => s.removeWire)
  const { screenToFlowPosition } = useReactFlow()

  const [minimapMode, setMinimapMode] = useState<MinimapMode>('show')
  const [showParams, setShowParams] = useState(true)
  const [viewSelectedNode, setViewSelectedNode] = useState<SelectedMorphism | null>(null)
  const [editingEdge, setEditingEdge] = useState<{ id: string; label: string; x: number; y: number } | null>(null)

  const isEditMode = storeMode === 'edit'

  // === ONE FUNCTION builds everything. Both modes use this. ===
  const graph = useMemo(() => buildReactFlowGraph(diagram), [diagram])
  const initialNodes = useMemo(
    () => applyStoredPositions(graph.nodes, diagram.id),
    [graph.nodes, diagram.id],
  )

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(graph.edges)

  // Reset only when switching to a different diagram
  const prevDiagramIdRef = useRef(diagram.id)
  useEffect(() => {
    if (prevDiagramIdRef.current !== diagram.id) {
      prevDiagramIdRef.current = diagram.id
      setNodes(applyStoredPositions(graph.nodes, diagram.id))
      setEdges(graph.edges)
    }
  }, [diagram.id, graph, setNodes, setEdges])

  // When diagram content changes (same ID, e.g. after addWire/addMorphism in edit mode),
  // merge new nodes/edges without losing positions
  const prevGraphRef = useRef(graph)
  useEffect(() => {
    if (prevGraphRef.current === graph) return
    prevGraphRef.current = graph

    setNodes((current) => {
      const currentMap = new Map(current.map((n) => [n.id, n]))
      // Keep positions of existing nodes, add new ones from graph
      return graph.nodes.map((gn) => {
        const existing = currentMap.get(gn.id)
        if (existing) {
          // Preserve position, update data
          return { ...gn, position: existing.position, draggable: gn.draggable }
        }
        // New node -- apply stored position or use graph default
        const stored = loadPositions(diagram.id)
        const pos = stored[gn.id]
        return pos ? { ...gn, position: pos } : gn
      })
    })

    setEdges(graph.edges)
  }, [graph, diagram.id, setNodes, setEdges])

  // Save positions on drag + sync wall-variable alignment
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const handleNodesChange = useCallback(
    (changes: NodeChange[]) => {
      onNodesChange(changes)
      const hasPositionChange = changes.some((c) => c.type === 'position')
      if (hasPositionChange) {
        setNodes((current) => {
          let changed = false
          const wallNode = current.find((n) => n.type === 'wallNode')

          const updated = current.map((n) => {
            // Sync anchor nodes with fan-out nodes
            if (n.id.startsWith('anchor-')) {
              const inputId = n.id.replace('anchor-', '')
              const fanOutNode = current.find((fn) => fn.id.startsWith('fanout-') && fn.id.includes(inputId))
              if (fanOutNode) {
                const targetX = fanOutNode.position.x - 120
                const targetY = fanOutNode.position.y
                if (n.position.x !== targetX || n.position.y !== targetY) {
                  changed = true
                  return { ...n, position: { x: targetX, y: targetY } }
                }
              }
            }
            // Sync variable nodes with wall position
            if (n.type === 'variableNode' && wallNode) {
              const targetX = wallNode.position.x - 69
              if (n.position.x !== targetX) {
                changed = true
                return { ...n, position: { ...n.position, x: targetX } }
              }
            }
            return n
          })

          if (saveTimerRef.current) clearTimeout(saveTimerRef.current)
          saveTimerRef.current = setTimeout(() => {
            setNodes((cur) => { savePositions(diagram.id, cur); return cur })
          }, 300)

          return changed ? updated : current
        })
      }
    },
    [onNodesChange, diagram.id, setNodes],
  )

  // --- Interaction handlers ---

  // Edge click: edit label
  const onEdgeClick = useCallback(
    (event: React.MouseEvent, edge: Edge) => {
      if (isEditMode) {
        setEditingEdge({
          id: edge.id,
          label: (edge.label as string) || '',
          x: event.clientX,
          y: event.clientY,
        })
      }
      setSelectedNode(null)
      setViewSelectedNode(null)
    },
    [isEditMode, setSelectedNode],
  )

  function confirmEdgeRename(newLabel: string) {
    if (editingEdge) {
      const label = newLabel.trim() || '?'
      renameWire(editingEdge.id, label)
      setEditingEdge(null)
    }
  }

  // Node click
  const onNodeClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      const data = node.data as Record<string, unknown>

      if (isEditMode) {
        setSelectedNode(node.id)
        return
      }

      if (node.type === 'morphismBox') {
        setViewSelectedNode({
          id: node.id,
          label: (data.label as string) || '',
          haskellSig: buildSignature(node.id, diagram),
          haskellClass: (data.haskellClass as string) || '',
          instances: (data.instances as { universe: string; def: string }[]) || [],
          mode: (data.mode as string) || 'tarski',
        })
      }
    },
    [isEditMode, setSelectedNode, diagram],
  )

  // Double-click on canvas to create node
  const lastPaneClickRef = useRef<{ time: number; x: number; y: number }>({ time: 0, x: 0, y: 0 })

  const createNodeAtPosition = useCallback(
    (clientX: number, clientY: number) => {
      const position = screenToFlowPosition({ x: clientX, y: clientY })
      const newId = addMorphismAtPosition(position.x, position.y)
      // Add immediately for instant feedback
      setNodes((current) => [...current, {
        id: newId,
        type: 'morphismBox',
        position: { x: position.x - 50, y: position.y - 22 },
        data: {
          label: 'f',
          haskellSig: '',
          haskellClass: '',
          instances: [],
          mode: 'tarski',
          layer: 'domain',
          accent: theme.node.accentBlue,
          inputs: [{ id: `${newId}-in-0`, label: '', position: 'left' }],
          outputs: [{ id: `${newId}-out-0`, label: '', position: 'right' }],
          paramInputs: [],
          isNew: true,
        },
      }])
      return newId
    },
    [screenToFlowPosition, addMorphismAtPosition, setNodes],
  )

  const onPaneClick = useCallback(
    (event: React.MouseEvent) => {
      if (!isEditMode) return
      const now = Date.now()
      const last = lastPaneClickRef.current
      const dx = Math.abs(event.clientX - last.x)
      const dy = Math.abs(event.clientY - last.y)
      if (now - last.time < 400 && dx < 10 && dy < 10) {
        createNodeAtPosition(event.clientX, event.clientY)
        lastPaneClickRef.current = { time: 0, x: 0, y: 0 }
      } else {
        lastPaneClickRef.current = { time: now, x: event.clientX, y: event.clientY }
      }
    },
    [isEditMode, createNodeAtPosition],
  )

  // Edge drop: create node on empty canvas
  const connectStartRef = useRef<{ nodeId: string; handleId: string } | null>(null)

  const onConnectStart = useCallback(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (_event: any, params: { nodeId: string | null; handleId: string | null }) => {
      if (params.nodeId && params.handleId) {
        connectStartRef.current = { nodeId: params.nodeId, handleId: params.handleId }
      }
    },
    [],
  )

  const onConnectEnd = useCallback(
    (event: MouseEvent | TouchEvent) => {
      if (!isEditMode || !connectStartRef.current) return
      const target = (event as MouseEvent).target as HTMLElement
      const isOnNodeOrHandle = target.closest('.react-flow__node') || target.closest('.react-flow__handle')
      if (isOnNodeOrHandle) {
        connectStartRef.current = null
        return
      }
      const { clientX, clientY } = 'changedTouches' in event
        ? (event as TouchEvent).changedTouches[0]
        : (event as MouseEvent)
      const newId = createNodeAtPosition(clientX, clientY)
      const { nodeId: sourceNodeId, handleId: sourceHandleId } = connectStartRef.current
      const wireId = `wire-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
      addWire({
        id: wireId,
        sourceBox: sourceNodeId,
        sourcePort: sourceHandleId,
        targetBox: newId,
        targetPort: `${newId}-in-0`,
        wireType: '?',
        isMonadic: false,
      })
      connectStartRef.current = null
    },
    [isEditMode, createNodeAtPosition, addWire],
  )

  // Delete sync
  const onNodesDelete = useCallback(
    (deleted: Node[]) => {
      for (const n of deleted) {
        if (n.type === 'morphismBox') removeMorphism(n.id)
      }
    },
    [removeMorphism],
  )

  const onEdgesDelete = useCallback(
    (deleted: Edge[]) => {
      for (const e of deleted) removeWire(e.id)
    },
    [removeWire],
  )

  // Connect handler
  const onConnect = useCallback(
    (connection: Connection) => {
      connectStartRef.current = null
      if (!connection.source || !connection.target) return
      const sourceHandle = connection.sourceHandle ?? connection.source
      const targetHandle = connection.targetHandle ?? connection.target

      const liveDiagram = useDiagramStore.getState().editorDiagram ?? diagram
      const result = validateConnection(connection.source, sourceHandle, connection.target, targetHandle, liveDiagram)
      if (!result.valid) {
        console.warn('Invalid connection:', result.reason)
        return
      }

      // Use variable label as wireType if source is a variable
      const sourceVar = liveDiagram.inputs.find((i) => i.id === connection.source)
      const wireType = sourceVar?.label ?? '?'

      const wireId = `wire-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
      addWire({
        id: wireId,
        sourceBox: connection.source,
        sourcePort: sourceHandle,
        targetBox: connection.target,
        targetPort: targetHandle,
        wireType,
        isMonadic: false,
      })
    },
    [addWire, diagram],
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
        onEdgeClick={onEdgeClick}
        onPaneClick={isEditMode ? onPaneClick : undefined}
        onConnect={isEditMode ? onConnect : undefined}
        onConnectStart={isEditMode ? onConnectStart : undefined}
        onConnectEnd={isEditMode ? onConnectEnd : undefined}
        onNodesDelete={isEditMode ? onNodesDelete : undefined}
        onEdgesDelete={isEditMode ? onEdgesDelete : undefined}
        deleteKeyCode={isEditMode ? ['Delete', 'Backspace'] : null}
        nodeTypes={nodeTypes}
        nodesDraggable={true}
        nodesConnectable={isEditMode}
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
      {isEditMode ? (
        <EditorToolbar />
      ) : (
        <div
          style={{
            position: 'absolute',
            top: 12,
            left: 'var(--controls-left, 12px)',
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
          <div className="sd-toolbar-group">
            <button
              className="sd-toolbar-btn"
              onClick={() => useDiagramStore.getState().setMode('edit')}
              style={{ color: theme.text.dimmed, fontSize: 11, padding: '0 10px' }}
            >
              Edit
            </button>
          </div>
        </div>
      )}

      {/* Detail panels -- same in both modes */}
      {!isEditMode && viewSelectedNode && (
        <NodeDetail
          label={viewSelectedNode.label}
          haskellSig={viewSelectedNode.haskellSig}
          haskellClass={viewSelectedNode.haskellClass}
          instances={viewSelectedNode.instances}
          mode={viewSelectedNode.mode}
          onClose={() => setViewSelectedNode(null)}
        />
      )}

      {isEditMode && selectedNodeId && (
        <NodeEditor
          morphismId={selectedNodeId}
          onClose={() => setSelectedNode(null)}
        />
      )}

      {/* Inline edge label editor */}
      {editingEdge && (
        <div style={{ position: 'fixed', left: editingEdge.x - 60, top: editingEdge.y - 16, zIndex: 100 }}>
          <input
            autoFocus
            defaultValue={editingEdge.label === '?' ? '' : editingEdge.label}
            placeholder="type name..."
            onKeyDown={(e) => {
              if (e.key === 'Enter') confirmEdgeRename((e.target as HTMLInputElement).value)
              if (e.key === 'Escape') setEditingEdge(null)
            }}
            onBlur={(e) => confirmEdgeRename(e.target.value)}
            style={{
              padding: '4px 8px',
              fontSize: 12,
              borderRadius: 4,
              border: `1px solid rgba(${theme.node.accentBlue}, 0.4)`,
              background: 'rgba(15,15,20,0.9)',
              color: theme.text.primary,
              outline: 'none',
              fontFamily: 'inherit',
              width: 120,
            }}
          />
        </div>
      )}
    </div>
  )
}
