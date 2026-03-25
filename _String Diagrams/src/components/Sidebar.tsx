import { useState, useRef, useEffect } from 'react'
import type { StringDiagram } from '../model/types'
import theme, { panelStyle, glassBlur } from '../lib/theme'
import { useDiagramStore } from '../store/diagramStore'

interface Props {
  diagrams: StringDiagram[]
  activeDiagram: string
  onSelect: (id: string) => void
  open: boolean
  onToggle: () => void
}

export default function Sidebar({ diagrams, activeDiagram, onSelect, open, onToggle }: Props) {
  const createNewDiagram = useDiagramStore((s) => s.createNewDiagram)
  const editorDiagram = useDiagramStore((s) => s.editorDiagram)
  const mode = useDiagramStore((s) => s.mode)

  // Inline naming state: when not null, shows an input field for a new diagram
  const [naming, setNaming] = useState(false)
  const [newName, setNewName] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (naming && inputRef.current) {
      inputRef.current.focus()
    }
  }, [naming])

  // Track the ID of the diagram being named
  const [namingId, setNamingId] = useState<string | null>(null)
  const updateTitle = useDiagramStore((s) => s.updateEditorTitle)

  function handleCreate() {
    // Create immediately with a placeholder name so it becomes active + blank canvas shows
    createNewDiagram('Untitled')
    const newId = useDiagramStore.getState().activeId
    setNamingId(newId)
    setNaming(true)
    setNewName('')
  }

  function confirmCreate() {
    if (newName.trim() && namingId) {
      updateTitle(newName.trim())
    }
    setNaming(false)
    setNamingId(null)
  }

  function cancelCreate() {
    if (newName.trim() && namingId) {
      updateTitle(newName.trim())
    }
    setNaming(false)
    setNamingId(null)
  }

  return (
    <>
      {/* Sidebar panel */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: 240,
          height: '100%',
          ...panelStyle(),
          borderTop: 'none',
          borderBottom: 'none',
          borderLeft: 'none',
          display: 'flex',
          flexDirection: 'column',
          zIndex: 10,
          transform: open ? 'translateX(0)' : 'translateX(-100%)',
          transition: 'transform 0.25s ease',
        }}
      >
        {/* Header with + button */}
        <div
          style={{
            padding: '14px 16px',
            borderBottom: `1px solid ${theme.glass.borderColor}`,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div>
            <div style={{ fontWeight: 700, fontSize: 15, color: theme.text.primary, textShadow: theme.text.shadow }}>
              String Diagrams
            </div>
            <div style={{ fontSize: 10, fontWeight: 400, color: theme.text.dimmed, marginTop: 2 }}>
              NeSyCat categorical logic
            </div>
          </div>
          <button
            onClick={handleCreate}
            title="New diagram"
            style={{
              width: 26,
              height: 26,
              borderRadius: 6,
              border: `1px solid ${theme.glass.borderColor}`,
              background: theme.glass.buttonBg,
              color: theme.text.secondary,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 16,
              lineHeight: 1,
              flexShrink: 0,
            }}
          >
            +
          </button>
        </div>

        {/* Section label */}
        <div
          style={{
            padding: '10px 12px 6px',
            fontSize: 10,
            fontWeight: 600,
            color: theme.text.dimmed,
            textTransform: 'uppercase' as const,
            letterSpacing: '0.05em',
          }}
        >
          Diagrams
        </div>

        {/* Diagram list */}
        <div style={{ flex: 1, overflow: 'auto' }}>
          {diagrams.map((d) => {
            const isActive = d.id === activeDiagram
            const isBeingNamed = naming && d.id === namingId
            const title = (mode === 'edit' && editorDiagram?.id === d.id)
              ? editorDiagram.title
              : d.title
            return (
              <div
                key={d.id}
                onClick={() => { if (!isBeingNamed) onSelect(d.id) }}
                style={{
                  padding: '10px 16px',
                  cursor: isBeingNamed ? 'default' : 'pointer',
                  background: isActive ? `rgba(${theme.node.accentIndigo},0.15)` : 'transparent',
                  borderLeft: isActive
                    ? `3px solid rgba(${theme.node.accentIndigo},0.8)`
                    : '3px solid transparent',
                  transition: 'all 0.15s ease',
                }}
              >
                {isBeingNamed ? (
                  <input
                    ref={inputRef}
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') confirmCreate()
                      if (e.key === 'Escape') cancelCreate()
                    }}
                    onBlur={() => confirmCreate()}
                    placeholder="Diagram name..."
                    style={{
                      width: '100%',
                      padding: '4px 8px',
                      fontSize: 13,
                      fontWeight: 500,
                      borderRadius: 4,
                      border: `1px solid rgba(${theme.node.accentIndigo}, 0.4)`,
                      background: 'rgba(255,255,255,0.04)',
                      color: theme.text.primary,
                      outline: 'none',
                      fontFamily: 'inherit',
                      boxSizing: 'border-box' as const,
                    }}
                  />
                ) : (
                  <>
                    <div
                      style={{
                        fontWeight: 500,
                        fontSize: 13,
                        color: isActive ? theme.text.primary : theme.text.secondary,
                        textShadow: theme.text.shadowLight,
                      }}
                    >
                      {title}
                    </div>
                    <div
                      style={{
                        fontSize: 11,
                        color: theme.text.dimmed,
                        marginTop: 3,
                      }}
                    >
                      {d.description || `${d.morphisms.length} morphisms`}
                    </div>
                  </>
                )}
              </div>
            )
          })}
        </div>
      </div>

      {/* Toggle ribbon button */}
      <button
        onClick={onToggle}
        style={{
          position: 'absolute',
          top: '50%',
          left: open ? 240 : 0,
          transform: 'translateY(-50%)',
          zIndex: 11,
          background: theme.glass.panelBg,
          ...glassBlur(),
          border: `1px solid ${theme.glass.borderColor}`,
          borderLeft: 'none',
          borderRadius: '0 8px 8px 0',
          color: theme.text.secondary,
          cursor: 'pointer',
          padding: '20px 6px',
          fontSize: 18,
          lineHeight: 1,
          transition: 'left 0.25s ease',
          display: 'flex',
          alignItems: 'center',
        }}
      >
        {open ? '\u2039' : '\u203A'}
      </button>
    </>
  )
}
