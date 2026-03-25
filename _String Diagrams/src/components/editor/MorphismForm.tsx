import { useState } from 'react'
import theme, { panelStyle } from '../../lib/theme'
import { useDiagramStore } from '../../store/diagramStore'
import type { MorphismMode, PortDef } from '../../model/types'

interface Props {
  onClose: () => void
}

interface PortEntry {
  label: string
  wireType: string
}

export default function MorphismForm({ onClose }: Props) {
  const addMorphism = useDiagramStore((s) => s.addMorphism)
  const [name, setName] = useState('')
  const [mode, setMode] = useState<MorphismMode>('tarski')
  const [inputs, setInputs] = useState<PortEntry[]>([{ label: '', wireType: 'Point U' }])
  const [outputs, setOutputs] = useState<PortEntry[]>([{ label: '', wireType: 'Omega U' }])
  const [params, setParams] = useState<PortEntry[]>([])

  const isValid = name.match(/^[a-z][a-zA-Z0-9']*$/) && outputs.length > 0

  function buildSig(): string {
    const allParts = [
      ...params.map((p) => p.wireType || '?'),
      ...inputs.map((p) => p.wireType || '?'),
    ]
    const outType = outputs[0]?.wireType || '?'
    const ret = mode === 'kleisli' ? `M U (${outType})` : outType
    return `${name} :: ${[...allParts, ret].join(' -> ')}`
  }

  function handleSubmit() {
    if (!isValid) return
    const id = `${name}-${Date.now()}`
    const morphInputs: PortDef[] = inputs.map((p, i) => ({
      id: `${id}-in-${i}`,
      label: p.wireType,
      position: 'left' as const,
    }))
    const morphOutputs: PortDef[] = outputs.map((p, i) => ({
      id: `${id}-out-${i}`,
      label: mode === 'kleisli' ? `M(${p.wireType})` : p.wireType,
      position: 'right' as const,
    }))
    const morphParams: PortDef[] | undefined = params.length > 0
      ? params.map((p, i) => ({
          id: `${id}-param-${i}`,
          label: p.wireType,
          position: 'top' as const,
        }))
      : undefined

    addMorphism({
      id,
      label: name,
      haskellSig: buildSig(),
      haskellClass: '',
      instances: [],
      mode,
      layer: 'domain',
      inputs: morphInputs,
      outputs: morphOutputs,
      paramInputs: morphParams,
    })
    onClose()
  }

  return (
    <div style={{ ...panelStyle(), borderRadius: 12, padding: 16, width: 340, maxHeight: '80vh', overflow: 'auto' }}>
      <div style={{ color: theme.text.primary, fontSize: 13, fontWeight: 600, marginBottom: 12 }}>
        Add Domain Morphism
      </div>

      {/* Name */}
      <Label text="Name" />
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="myFunc" style={inputStyle} autoFocus />
      {name && !name.match(/^[a-z][a-zA-Z0-9']*$/) && (
        <div style={{ color: 'rgba(255,100,100,0.8)', fontSize: 10, marginTop: 2 }}>
          Must start with lowercase, only alphanumeric + '
        </div>
      )}

      {/* Mode */}
      <Label text="Mode" />
      <div style={{ display: 'flex', gap: 4, marginBottom: 8 }}>
        {(['tarski', 'kleisli'] as const).map((m) => (
          <button
            key={m}
            onClick={() => setMode(m)}
            style={{
              ...btnStyle,
              background: mode === m
                ? `rgba(${m === 'kleisli' ? theme.node.accentPurple : theme.node.accentBlue}, 0.3)`
                : theme.glass.buttonBg,
              color: mode === m ? theme.text.primary : theme.text.muted,
            }}
          >
            {m}
          </button>
        ))}
      </div>

      {/* Inputs */}
      <PortList label="Inputs (left)" entries={inputs} onChange={setInputs} />

      {/* Params */}
      <PortList label="Parameters (top)" entries={params} onChange={setParams} />

      {/* Outputs */}
      <PortList label="Outputs (right)" entries={outputs} onChange={setOutputs} />

      {/* Signature preview */}
      <Label text="Signature preview" />
      <pre style={{ color: theme.text.muted, fontSize: 10, fontFamily: 'SF Mono, Menlo, monospace', margin: '4px 0 12px', whiteSpace: 'pre-wrap' }}>
        {buildSig()}
      </pre>

      {/* Submit */}
      <button
        onClick={handleSubmit}
        disabled={!isValid}
        style={{
          ...btnStyle,
          width: '100%',
          opacity: isValid ? 1 : 0.4,
          background: `rgba(${theme.node.accentBlue}, 0.3)`,
          color: theme.text.primary,
        }}
      >
        Add Morphism
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

function PortList({ label, entries, onChange }: { label: string; entries: PortEntry[]; onChange: (e: PortEntry[]) => void }) {
  return (
    <>
      <Label text={label} />
      {entries.map((entry, i) => (
        <div key={i} style={{ display: 'flex', gap: 4, marginBottom: 4 }}>
          <input
            value={entry.wireType}
            onChange={(e) => {
              const next = [...entries]
              next[i] = { ...entry, wireType: e.target.value }
              onChange(next)
            }}
            placeholder="Wire type"
            style={{ ...inputStyle, flex: 1 }}
          />
          <button
            onClick={() => onChange(entries.filter((_, j) => j !== i))}
            style={{ ...btnStyle, padding: '4px 6px', fontSize: 10 }}
          >
            x
          </button>
        </div>
      ))}
      <button
        onClick={() => onChange([...entries, { label: '', wireType: '' }])}
        style={{ ...btnStyle, fontSize: 10, marginBottom: 4 }}
      >
        + add
      </button>
    </>
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
  border: `1px solid rgba(255,255,255,0.08)`,
  background: 'rgba(255,255,255,0.06)',
  color: 'rgba(255,255,255,0.8)',
  cursor: 'pointer',
}
