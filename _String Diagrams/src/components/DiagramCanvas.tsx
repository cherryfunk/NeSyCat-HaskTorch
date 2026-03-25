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
import { layoutDiagram } from '../lib/layout'
import { validateConnection } from '../lib/connectionValidator'
import theme from '../lib/theme'
import { useDiagramStore } from '../store/diagramStore'
import MorphismNode from './MorphismNode'
import EndpointNode from './EndpointNode'
import CopyDot from './CopyDot'
import NodeDetail from './NodeDetail'
import EditorToolbar from './editor/EditorToolbar'
import NodeEditor from './editor/NodeEditor'

const nodeTypes = {
  morphismBox: MorphismNode,
  endpoint: EndpointNode,
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
const POS_KEY = 'sd-node-positions'

function loadPositions(diagramId: string): Record<string, { x: number; y: number }> {
  try {
    const raw = localStorage.getItem(POS_KEY)
    if (!raw) return {}
    const all = JSON.parse(raw)
    return all[diagramId] ?? {}
  } catch {
    return {}
  }
}

function savePositions(diagramId: string, nodes: Node[]) {
  try {
    const raw = localStorage.getItem(POS_KEY)
    const all = raw ? JSON.parse(raw) : {}
    const positions: Record<string, { x: number; y: number }> = {}
    for (const n of nodes) {
      positions[n.id] = n.position
    }
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
  inputs: { id: string; label: string; position: string }[]
  outputs: { id: string; label: string; position: string }[]
  paramInputs: { id: string; label: string; position: string }[]
}

interface Props {
  diagram: StringDiagram
  sidebarWidth: number
}

function resolvePortLabel(nodeId: string, handleId: string, diagram: StringDiagram): string {
  const morph = diagram.morphisms.find((m) => m.id === nodeId)
  if (morph) {
    const port = morph.outputs.find((p) => p.id === handleId)
      ?? morph.inputs.find((p) => p.id === handleId)
      ?? morph.paramInputs?.find((p) => p.id === handleId)
    if (port) return port.label
  }
  return ''
}

export default function DiagramCanvas({ diagram, sidebarWidth }: Props) {
  const storeMode = useDiagramStore((s) => s.mode)
  const addWire = useDiagramStore((s) => s.addWire)
  const setSelectedNode = useDiagramStore((s) => s.setSelectedNode)
  const selectedNodeId = useDiagramStore((s) => s.selectedNodeId)
  const addMorphismAtPosition = useDiagramStore((s) => s.addMorphismAtPosition)
  const { screenToFlowPosition } = useReactFlow()

  const [minimapMode, setMinimapMode] = useState<MinimapMode>('show')
  const [showParams, setShowParams] = useState(true)
  const [viewSelectedNode, setViewSelectedNode] = useState<SelectedMorphism | null>(null)

  const isEditMode = storeMode === 'edit'

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

  const initialNodes = useMemo(
    () => applyStoredPositions(layout.nodes, diagram.id),
    [layout.nodes, diagram.id],
  )

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(layout.edges)

  // Save positions on drag
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const handleNodesChange = useCallback(
    (changes: NodeChange[]) => {
      onNodesChange(changes)
      const hasPositionChange = changes.some((c) => c.type === 'position')
      if (hasPositionChange) {
        setNodes((current) => {
          let changed = false
          const updated = current.map((n) => {
            if (n.id.startsWith('anchor-')) {
              const inputId = n.id.replace('anchor-', '')
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

  // Reset when diagram changes
  // Reset nodes/edges when diagram object changes (view mode only)
  const prevDiagramRef = useRef(diagram)
  useEffect(() => {
    if (!isEditMode && prevDiagramRef.current !== diagram) {
      prevDiagramRef.current = diagram
      const restored = applyStoredPositions(layout.nodes, diagram.id)
      setNodes(restored)
      setEdges(layout.edges)
    }
  }, [diagram, layout, setNodes, setEdges, isEditMode])

  // In edit mode, sync morphism data (ports, label, etc.) from store to ReactFlow nodes
  // without changing positions.
  const editorDiagram = useDiagramStore((s) => s.editorDiagram)
  // Serialize editorDiagram morphisms to detect changes
  const morphDataKey = editorDiagram?.morphisms.map(
    (m) => `${m.id}:${m.label}:${m.inputs.length}:${m.outputs.length}:${m.paramInputs?.length ?? 0}`
  ).join('|') ?? ''

  useEffect(() => {
    if (!isEditMode || !editorDiagram) return
    const morphMap = new Map(editorDiagram.morphisms.map((m) => [m.id, m]))
    const morphIds = new Set(editorDiagram.morphisms.map((m) => m.id))

    // Update existing nodes and remove deleted ones
    setNodes((current) =>
      current
        .filter((n) => n.type !== 'morphismBox' || morphIds.has(n.id))
        .map((n) => {
          const morph = morphMap.get(n.id)
          if (!morph || n.type !== 'morphismBox') return n
          return {
            ...n,
            data: {
              ...n.data,
              label: morph.label,
              haskellSig: morph.haskellSig,
              haskellClass: morph.haskellClass,
              instances: morph.instances,
              mode: morph.mode,
              layer: morph.layer,
              inputs: morph.inputs,
              outputs: morph.outputs,
              paramInputs: morph.paramInputs ?? [],
            },
          }
        })
    )

    // Also remove edges connected to deleted morphisms
    setEdges((current) =>
      current.filter((e) => {
        // Keep edges where both source and target still exist as morphisms or other node types
        const sourceExists = morphIds.has(e.source) || !e.source.startsWith('morph-')
        const targetExists = morphIds.has(e.target) || !e.target.startsWith('morph-')
        return sourceExists && targetExists
      })
    )
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEditMode, morphDataKey, setNodes, setEdges])

  // Toggle params (view mode only -- in edit mode, edges are managed manually)
  useEffect(() => {
    if (isEditMode) return
    setNodes((currentNodes) => {
      if (showParams) {
        const currentIds = new Set(currentNodes.map((n) => n.id))
        const stored = loadPositions(diagram.id)
        const paramNodesToAdd = layout.nodes
          .filter((n) => paramInfo.topInputIds.has(n.id) && !currentIds.has(n.id))
          .map((n) => { const pos = stored[n.id]; return pos ? { ...n, position: pos } : n })
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
  }, [showParams, layout, paramInfo, setNodes, setEdges, diagram.id, isEditMode])

  // Node click
  const onNodeClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      const data = node.data as Record<string, unknown>

      if (isEditMode) {
        setSelectedNode(node.id)
        return
      }

      // In view mode, show NodeDetail only for morphism nodes
      if (node.type === 'morphismBox') {
        setViewSelectedNode({
          id: node.id,
          label: (data.label as string) || '',
          haskellSig: (data.haskellSig as string) || '',
          haskellClass: (data.haskellClass as string) || '',
          instances: (data.instances as { universe: string; def: string }[]) || [],
          mode: (data.mode as string) || 'tarski',
          inputs: (data.inputs as { id: string; label: string; position: string }[]) || [],
          outputs: (data.outputs as { id: string; label: string; position: string }[]) || [],
          paramInputs: (data.paramInputs as { id: string; label: string; position: string }[]) || [],
        })
      }
    },
    [isEditMode, setSelectedNode],
  )

  // Double-click on empty canvas to create a new node
  // ReactFlow has no onPaneDoubleClick, so we detect double-click via timing on onPaneClick
  const lastPaneClickRef = useRef<{ time: number; x: number; y: number }>({ time: 0, x: 0, y: 0 })

  const createNodeAtPosition = useCallback(
    (clientX: number, clientY: number) => {
      const position = screenToFlowPosition({ x: clientX, y: clientY })
      const newId = addMorphismAtPosition(position.x, position.y)
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
        // Double-click detected
        createNodeAtPosition(event.clientX, event.clientY)
        lastPaneClickRef.current = { time: 0, x: 0, y: 0 }
      } else {
        lastPaneClickRef.current = { time: now, x: event.clientX, y: event.clientY }
      }
    },
    [isEditMode, createNodeAtPosition],
  )

  // Add node on edge drop: when user drags a connection and drops on empty canvas
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

      // Check if the drop landed on empty canvas (not on a node or handle)
      const target = (event as MouseEvent).target as HTMLElement
      const isOnNodeOrHandle = target.closest('.react-flow__node') || target.closest('.react-flow__handle')
      if (isOnNodeOrHandle) {
        connectStartRef.current = null
        return
      }

      // Create a new node at the drop position
      const { clientX, clientY } = 'changedTouches' in event
        ? (event as TouchEvent).changedTouches[0]
        : (event as MouseEvent)
      const newId = createNodeAtPosition(clientX, clientY)

      // Connect the source to the new node's first input
      const { nodeId: sourceNodeId, handleId: sourceHandleId } = connectStartRef.current
      const wireId = `wire-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
      addWire({
        id: wireId,
        sourceBox: sourceNodeId,
        sourcePort: sourceHandleId,
        targetBox: newId,
        targetPort: `${newId}-in-0`,
        wireType: 'Omega U',
        isMonadic: false,
      })

      // Also add the edge directly to ReactFlow
      setEdges((eds) => [...eds, {
        id: wireId,
        source: sourceNodeId,
        target: newId,
        sourceHandle: sourceHandleId,
        targetHandle: `${newId}-in-0`,
        type: 'smoothstep',
        animated: true,
        style: { stroke: `rgba(${theme.node.accentBlue}, 0.5)`, strokeWidth: 2 },
      }])

      connectStartRef.current = null
    },
    [isEditMode, createNodeAtPosition, addWire, setEdges],
  )

  // Sync keyboard deletions to the store
  const removeMorphism = useDiagramStore((s) => s.removeMorphism)
  const removeWire = useDiagramStore((s) => s.removeWire)

  const onNodesDelete = useCallback(
    (deleted: Node[]) => {
      for (const n of deleted) {
        if (n.type === 'morphismBox') {
          removeMorphism(n.id)
        }
      }
    },
    [removeMorphism],
  )

  const onEdgesDelete = useCallback(
    (deleted: Edge[]) => {
      for (const e of deleted) {
        removeWire(e.id)
      }
    },
    [removeWire],
  )

  // Connection handler for edit mode with type validation
  const onConnect = useCallback(
    (connection: Connection) => {
      // Clear connectStartRef so onConnectEnd knows this was handled
      connectStartRef.current = null

      if (!connection.source || !connection.target) return
      const sourceHandle = connection.sourceHandle ?? connection.source
      const targetHandle = connection.targetHandle ?? connection.target

      const result = validateConnection(
        connection.source,
        sourceHandle,
        connection.target,
        targetHandle,
        diagram,
      )

      if (!result.valid) {
        console.warn('Invalid connection:', result.reason)
        return
      }

      // Resolve the port label for the edge label
      const portLabel = resolvePortLabel(connection.source, sourceHandle, diagram)

      const wireId = `wire-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
      addWire({
        id: wireId,
        sourceBox: connection.source,
        sourcePort: sourceHandle,
        targetBox: connection.target,
        targetPort: targetHandle,
        wireType: portLabel || result.wireType,
        isMonadic: false,
      })

      // Add edge to ReactFlow directly with label
      setEdges((eds) => [...eds, {
        id: wireId,
        source: connection.source!,
        target: connection.target!,
        sourceHandle,
        targetHandle,
        type: 'smoothstep',
        animated: true,
        label: portLabel || undefined,
        labelStyle: { fill: theme.text.dimmed, fontSize: 10, fontFamily: 'inherit' },
        labelBgStyle: { fill: theme.canvas.background, fillOpacity: 0.8 },
        style: { stroke: `rgba(${theme.node.accentBlue}, 0.5)`, strokeWidth: 2 },
      }])
    },
    [addWire, diagram, setEdges],
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

      {/* Toolbar -- edit mode uses EditorToolbar, view mode uses simple buttons */}
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

          {/* View/Edit mode toggle */}
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

      {/* Detail panels */}
      {!isEditMode && viewSelectedNode && (
        <NodeDetail
          label={viewSelectedNode.label}
          haskellSig={viewSelectedNode.haskellSig}
          haskellClass={viewSelectedNode.haskellClass}
          instances={viewSelectedNode.instances}
          mode={viewSelectedNode.mode}
          inputs={viewSelectedNode.inputs}
          outputs={viewSelectedNode.outputs}
          paramInputs={viewSelectedNode.paramInputs}
          onClose={() => setViewSelectedNode(null)}
        />
      )}

      {isEditMode && selectedNodeId && (
        <NodeEditor
          morphismId={selectedNodeId}
          onClose={() => setSelectedNode(null)}
        />
      )}
    </div>
  )
}
