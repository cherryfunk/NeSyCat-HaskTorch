import type { StringDiagram } from '../model/types'
import theme, { panelStyle, glassBlur } from '../lib/theme'

interface Props {
  diagrams: StringDiagram[]
  activeDiagram: string
  onSelect: (id: string) => void
  open: boolean
  onToggle: () => void
}

export default function Sidebar({ diagrams, activeDiagram, onSelect, open, onToggle }: Props) {
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
        {/* Header */}
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
            return (
              <div
                key={d.id}
                onClick={() => onSelect(d.id)}
                style={{
                  padding: '10px 16px',
                  cursor: 'pointer',
                  background: isActive ? `rgba(${theme.node.accentIndigo},0.15)` : 'transparent',
                  borderLeft: isActive
                    ? `3px solid rgba(${theme.node.accentIndigo},0.8)`
                    : '3px solid transparent',
                  transition: 'all 0.15s ease',
                }}
              >
                <div
                  style={{
                    fontWeight: 500,
                    fontSize: 13,
                    color: isActive ? theme.text.primary : theme.text.secondary,
                    textShadow: theme.text.shadowLight,
                  }}
                >
                  {d.title}
                </div>
                <div
                  style={{
                    fontSize: 11,
                    color: theme.text.dimmed,
                    marginTop: 3,
                  }}
                >
                  {d.description}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Toggle ribbon button -- slides with the sidebar */}
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
