import { useState } from 'react'
import theme, { panelStyle } from '../../lib/theme'
import { useDiagramStore } from '../../store/diagramStore'

interface Props {
  side: 'input' | 'output'
  onClose: () => void
}

export default function EndpointForm({ side, onClose }: Props) {
  const addInput = useDiagramStore((s) => s.addInput)
  const addOutput = useDiagramStore((s) => s.addOutput)
  const [label, setLabel] = useState('')
  const [wireType, setWireType] = useState(side === 'input' ? 'Point U' : 'M(Omega U)')
  const [inputSide, setInputSide] = useState<'left' | 'top'>('left')

  function handleSubmit() {
    if (!label.trim()) return
    const id = `${side}-${label.trim().toLowerCase()}-${Date.now()}`
    if (side === 'input') {
      addInput({ id, label: label.trim(), wireType, side: inputSide })
    } else {
      addOutput({ id, label: label.trim(), wireType })
    }
    onClose()
  }

  return (
    <div style={{ ...panelStyle(), borderRadius: 12, padding: 16, width: 280 }}>
      <div style={{ color: theme.text.primary, fontSize: 13, fontWeight: 600, marginBottom: 12 }}>
        Add {side === 'input' ? 'Input' : 'Output'}
      </div>

      <Label text="Label" />
      <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="e.g. Point" style={inputStyle} autoFocus />

      <Label text="Wire type" />
      <input value={wireType} onChange={(e) => setWireType(e.target.value)} placeholder="e.g. Point U" style={inputStyle} />

      {side === 'input' && (
        <>
          <Label text="Position" />
          <div style={{ display: 'flex', gap: 4, marginBottom: 8 }}>
            {(['left', 'top'] as const).map((s) => (
              <button
                key={s}
                onClick={() => setInputSide(s)}
                style={{
                  ...btnStyle,
                  background: inputSide === s ? `rgba(${theme.node.accentIndigo}, 0.3)` : undefined,
                  color: inputSide === s ? theme.text.primary : theme.text.muted,
                }}
              >
                {s === 'left' ? 'Left (data)' : 'Top (param)'}
              </button>
            ))}
          </div>
        </>
      )}

      <button onClick={handleSubmit} style={{ ...btnStyle, width: '100%', marginTop: 8, background: `rgba(${theme.node.accentBlue}, 0.3)`, color: theme.text.primary }}>
        Add
      </button>
    </div>
  )
}

function Label({ text }: { text: string }) {
  return (
    <div style={{ color: theme.text.dimmed, fontSize: 10, marginTop: 8, marginBottom: 4, textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>
      {text}
    </div>
  )
}

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '6px 10px',
  fontSize: 12,
  borderRadius: 4,
  border: '1px solid rgba(255,255,255,0.1)',
  background: 'rgba(255,255,255,0.04)',
  color: '#fff',
  outline: 'none',
  fontFamily: 'inherit',
  boxSizing: 'border-box',
}

const btnStyle: React.CSSProperties = {
  padding: '4px 10px',
  fontSize: 11,
  borderRadius: 4,
  border: '1px solid rgba(255,255,255,0.08)',
  background: 'rgba(255,255,255,0.06)',
  color: 'rgba(255,255,255,0.8)',
  cursor: 'pointer',
}
