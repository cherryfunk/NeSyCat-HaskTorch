import { useState } from 'react'
import type { StringDiagram } from '../model/types'
import theme, { panelStyle } from '../lib/theme'

interface Props {
  diagrams: StringDiagram[]
  activeDiagram: string
  onSelect: (id: string) => void
}

export default function Sidebar({ diagrams, activeDiagram, onSelect }: Props) {
  const [open, setOpen] = useState(true)
  const width = 240

  return (
    <>
      {/* Sidebar panel */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width,
          height: '100%',
          ...panelStyle(),
          transform: open ? 'translateX(0)' : 'translateX(-100%)',
          transition: 'transform 0.25s ease',
          zIndex: 10,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* Header */}
        <div style={{ padding: '16px 16px 12px' }}>
          <div style={{ color: theme.text.primary, fontSize: 14, fontWeight: 600 }}>
            String Diagrams
          </div>
          <div style={{ color: theme.text.dimmed, fontSize: 11, marginTop: 2 }}>
            NeSyCat categorical logic
          </div>
        </div>

        {/* Diagram list */}
        <div style={{ flex: 1, overflow: 'auto', padding: '0 8px' }}>
          {diagrams.map((d) => {
            const isActive = d.id === activeDiagram
            return (
              <button
                key={d.id}
                onClick={() => onSelect(d.id)}
                style={{
                  display: 'block',
                  width: '100%',
                  textAlign: 'left',
                  padding: '10px 12px',
                  marginBottom: 4,
                  borderRadius: 6,
                  border: 'none',
                  cursor: 'pointer',
                  background: isActive
                    ? `rgba(${theme.node.accentIndigo}, 0.15)`
                    : 'transparent',
                  borderLeft: isActive
                    ? `3px solid rgba(${theme.node.accentIndigo}, 0.8)`
                    : '3px solid transparent',
                }}
              >
                <div style={{ color: theme.text.secondary, fontSize: 12, fontWeight: 500 }}>
                  {d.title}
                </div>
                <div style={{ color: theme.text.dimmed, fontSize: 10, marginTop: 2 }}>
                  {d.description}
                </div>
              </button>
            )
          })}
        </div>

        {/* Haskell source for active diagram */}
        <div style={{ padding: '12px 16px', borderTop: `1px solid ${theme.glass.borderColor}` }}>
          <div style={{ color: theme.text.dimmed, fontSize: 10, marginBottom: 4 }}>
            Haskell source
          </div>
          <pre
            style={{
              color: theme.text.muted,
              fontSize: 10,
              lineHeight: 1.5,
              margin: 0,
              whiteSpace: 'pre-wrap',
              fontFamily: 'SF Mono, Menlo, monospace',
            }}
          >
            {diagrams.find((d) => d.id === activeDiagram)?.haskellSource}
          </pre>
        </div>
      </div>

      {/* Toggle button */}
      <button
        onClick={() => setOpen(!open)}
        style={{
          position: 'absolute',
          top: '50%',
          left: open ? width : 0,
          transform: 'translateY(-50%)',
          transition: 'left 0.25s ease',
          zIndex: 11,
          width: 20,
          height: 48,
          borderRadius: '0 6px 6px 0',
          border: `1px solid ${theme.glass.borderColor}`,
          borderLeft: 'none',
          background: theme.glass.panelBg,
          color: theme.text.muted,
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 12,
        }}
      >
        {open ? '<' : '>'}
      </button>
    </>
  )
}
