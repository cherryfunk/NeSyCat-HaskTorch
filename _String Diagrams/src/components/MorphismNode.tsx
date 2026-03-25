import { memo, useState, useRef, useEffect } from 'react'
import { Handle, Position, useNodeConnections } from '@xyflow/react'
import type { NodeProps, HandleProps } from '@xyflow/react'
import theme, { glassBlur } from '../lib/theme'
import type { PortDef } from '../model/types'
import { useDiagramStore } from '../store/diagramStore'

interface MorphismData {
  label: string
  haskellSig: string
  haskellDef?: string
  haskellClass?: string
  instances?: { universe: string; def: string }[]
  mode: string
  layer?: string
  accent: string
  inputs: PortDef[]
  outputs: PortDef[]
  paramInputs: PortDef[]
  isNew?: boolean
}

function MorphismNode({ data, selected, id }: NodeProps) {
  const d = data as unknown as MorphismData
  const params = d.paramInputs ?? []
  const storeMode = useDiagramStore((s) => s.mode)
  const addPort = useDiagramStore((s) => s.addPortToMorphism)
  const rename = useDiagramStore((s) => s.renameMorphism)
  const isEditMode = storeMode === 'edit'

  const [editing, setEditing] = useState(false)
  const [editName, setEditName] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const autoEditDone = useRef(false)

  // Auto-start editing for newly created nodes
  useEffect(() => {
    if (isEditMode && d.isNew && !autoEditDone.current) {
      autoEditDone.current = true
      setEditing(true)
      setEditName('')
    }
  }, [isEditMode, d.isNew])

  useEffect(() => {
    if (editing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [editing])

  function startEditing() {
    setEditName(d.label === 'f' ? '' : d.label)
    setEditing(true)
  }

  function confirmRename() {
    const name = editName.trim()
    if (name && name !== d.label) {
      rename(id, name)
    }
    setEditing(false)
  }

  const fillOpacity = selected
    ? theme.node.selectedFillOpacity
    : theme.node.fillOpacity
  const borderOpacity = selected
    ? theme.node.selectedBorderOpacity
    : theme.node.borderOpacity

  // Scale height based on max port count so handles don't overlap
  const maxPorts = Math.max(d.inputs.length, d.outputs.length, 1)
  const minHeight = Math.max(36, maxPorts * 20 + 16)

  return (
    <div
      style={{
        background: `rgba(${d.accent}, ${fillOpacity})`,
        border: `1px solid rgba(${d.accent}, ${borderOpacity})`,
        borderRadius: 8,
        padding: '8px 16px',
        width: 100,
        minHeight,
        textAlign: 'center',
        display: 'flex',
        flexDirection: 'column' as const,
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        ...glassBlur(),
        boxShadow: selected
          ? `0 0 0 1px rgba(${d.accent},0.4), 0 4px 12px rgba(0,0,0,0.3)`
          : '0 1px 4px rgba(0,0,0,0.2)',
        transition: 'all 0.15s ease',
        position: 'relative',
      }}
      onDoubleClick={(e) => {
        if (isEditMode) {
          e.stopPropagation()
          startEditing()
        }
      }}
    >
      {/* Label or inline edit */}
      {editing ? (
        <input
          ref={inputRef}
          value={editName}
          onChange={(e) => setEditName(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') confirmRename()
            if (e.key === 'Escape') { setEditName(d.label); setEditing(false) }
          }}
          onBlur={confirmRename}
          style={{
            background: 'transparent',
            border: 'none',
            borderBottom: `1px solid rgba(${d.accent}, 0.5)`,
            color: theme.text.primary,
            fontSize: 13,
            fontWeight: 600,
            textAlign: 'center',
            outline: 'none',
            width: '100%',
            fontFamily: 'inherit',
            padding: 0,
            margin: 0,
            lineHeight: '1.3',
            boxSizing: 'border-box' as const,
          }}
        />
      ) : (
        <div
          style={{
            fontWeight: 600,
            fontSize: 13,
            color: theme.text.primary,
            textShadow: theme.text.shadowLight,
            lineHeight: '1.3',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {d.label}
        </div>
      )}

      {/* Left-side data inputs -- max 1 connection per handle */}
      {d.inputs.map((port: PortDef, i: number) => (
        <LimitedTargetHandle
          key={port.id}
          position={Position.Left}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.inputs.length + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.8)`,
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}

      {/* Top-side parameter inputs -- max 1 connection per handle */}
      {params.map((port: PortDef, i: number) => (
        <LimitedTargetHandle
          key={port.id}
          position={Position.Top}
          id={port.id}
          style={{
            left: `${((i + 1) / (params.length + 1)) * 100}%`,
            background: 'rgba(255,255,255,0.2)',
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}

      {/* Right-side outputs */}
      {d.outputs.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="source"
          position={Position.Right}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.outputs.length + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.8)`,
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}

      {/* + buttons for adding ports (only in edit mode when selected) */}
      {isEditMode && selected && (
        <>
          <button
            onClick={(e) => { e.stopPropagation(); addPort(id, 'input') }}
            style={plusBtnStyle('left')}
            title="Add input"
          >
            +
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); addPort(id, 'output') }}
            style={plusBtnStyle('right')}
            title="Add output"
          >
            +
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); addPort(id, 'param') }}
            style={plusBtnStyle('top')}
            title="Add parameter"
          >
            +
          </button>
        </>
      )}
    </div>
  )
}

// Target handle that allows max 1 connection
function LimitedTargetHandle(props: Omit<HandleProps, 'type'> & { style?: React.CSSProperties }) {
  const connections = useNodeConnections({ handleType: 'target', handleId: props.id ?? undefined })
  return <Handle {...props} type="target" isConnectable={connections.length < 1} />
}

function plusBtnStyle(side: 'left' | 'right' | 'top'): React.CSSProperties {
  const base: React.CSSProperties = {
    position: 'absolute',
    width: 16,
    height: 16,
    borderRadius: '50%',
    border: '1px solid rgba(255,255,255,0.15)',
    background: 'rgba(255,255,255,0.06)',
    color: 'rgba(255,255,255,0.5)',
    fontSize: 12,
    lineHeight: '14px',
    textAlign: 'center',
    cursor: 'pointer',
    padding: 0,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  }
  if (side === 'left') return { ...base, left: -24, top: '50%', transform: 'translateY(-50%)' }
  if (side === 'right') return { ...base, right: -24, top: '50%', transform: 'translateY(-50%)' }
  return { ...base, top: -24, left: '50%', transform: 'translateX(-50%)' }
}

export default memo(MorphismNode)
