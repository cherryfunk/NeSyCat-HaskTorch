import { memo, useState, useRef, useEffect } from 'react'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import theme from '../lib/theme'
import { useDiagramStore } from '../store/diagramStore'

interface VariableData {
  label: string
  isNew?: boolean
}

function VariableNode({ data, id }: NodeProps) {
  const d = data as unknown as VariableData
  const storeMode = useDiagramStore((s) => s.mode)
  const renameVariable = useDiagramStore((s) => s.renameVariable)
  const isEditMode = storeMode === 'edit'

  const [editing, setEditing] = useState(false)
  const [editName, setEditName] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const autoEditDone = useRef(false)

  // Auto-start editing for newly created variables
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
    setEditName(d.label === '?' ? '' : d.label)
    setEditing(true)
  }

  function confirmRename() {
    const name = editName.trim()
    if (name && name !== d.label) {
      renameVariable(id, name)
    }
    setEditing(false)
  }

  return (
    <div
      style={{
        padding: '0px 12px 0px 8px',
        width: 50,
        height: 20,
        textAlign: 'right',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-end',
      }}
      onDoubleClick={(e) => {
        if (isEditMode) {
          e.stopPropagation()
          startEditing()
        }
      }}
    >
      {editing ? (
        <input
          ref={inputRef}
          value={editName}
          onChange={(e) => setEditName(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') confirmRename()
            if (e.key === 'Escape') setEditing(false)
          }}
          onBlur={confirmRename}
          style={{
            background: 'transparent',
            border: 'none',
            borderBottom: `1px solid rgba(255,255,255,0.3)`,
            color: theme.text.secondary,
            fontSize: 11,
            fontWeight: 500,
            textAlign: 'right',
            outline: 'none',
            width: 40,
            fontFamily: 'SF Mono, Menlo, monospace',
            padding: 0,
          }}
        />
      ) : (
        <span
          style={{
            color: d.label === '?' ? theme.text.dimmed : theme.text.secondary,
            fontSize: 11,
            fontWeight: 500,
            fontFamily: 'SF Mono, Menlo, monospace',
          }}
        >
          {d.label}
        </span>
      )}

      <Handle
        type="source"
        position={Position.Right}
        id={`${id}-out`}
        style={{
          background: 'rgba(255,255,255,0.4)',
          width: 8,
          height: 8,
          border: 'none',
        }}
      />
    </div>
  )
}

export default memo(VariableNode)
