import theme, { panelStyle, buttonStyle as themeBtnStyle } from '../../lib/theme'
import { useDiagramStore } from '../../store/diagramStore'
import type { InstanceDef, PortDef } from '../../model/types'

interface Props {
  morphismId: string
  onClose: () => void
}

export default function NodeEditor({ morphismId, onClose }: Props) {
  const diagram = useDiagramStore((s) => s.editorDiagram)
  const updateMorphism = useDiagramStore((s) => s.updateMorphism)
  const removeMorphism = useDiagramStore((s) => s.removeMorphism)
  const renamePort = useDiagramStore((s) => s.renamePort)
  const addPort = useDiagramStore((s) => s.addPortToMorphism)
  const removePort = useDiagramStore((s) => s.removePortFromMorphism)

  const morph = diagram?.morphisms.find((m) => m.id === morphismId)
  if (!morph) return null

  // Auto-generate signature from ports
  const sig = morph.haskellSig || (() => {
    const parts: string[] = []
    for (const p of (morph.paramInputs ?? [])) parts.push(p.label || '?')
    for (const p of morph.inputs) parts.push(p.label || '?')
    if (morph.outputs.length > 0) {
      const out = morph.outputs[0].label || '?'
      parts.push(morph.mode === 'kleisli' ? `M U (${out})` : out)
    }
    return `${morph.label} :: ${parts.join(' -> ')}`
  })()

  return (
    <div
      style={{
        position: 'absolute',
        top: 16,
        right: 16,
        width: 320,
        maxHeight: 'calc(100% - 32px)',
        overflow: 'auto',
        ...panelStyle(),
        borderRadius: 12,
        zIndex: 10,
        boxShadow: '0 8px 32px rgba(0,0,0,0.4)',
      }}
    >
      {/* Header */}
      <div
        style={{
          padding: '10px 14px',
          borderBottom: `1px solid ${theme.glass.borderColor}`,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: 8,
        }}
      >
        <div>
          <div style={{ fontWeight: 700, fontSize: 13, color: theme.text.primary, textShadow: theme.text.shadow }}>
            {morph.label}
          </div>
          <div style={{ fontSize: 10, color: theme.text.dimmed, marginTop: 2 }}>
            {morph.mode} &middot; {morph.layer}{morph.haskellClass ? ` \u00b7 ${morph.haskellClass}` : ''}
          </div>
        </div>
        <button onClick={onClose} style={{ ...themeBtnStyle(), borderRadius: 4, fontSize: 12, cursor: 'pointer', padding: '1px 6px', flexShrink: 0 }}>
          x
        </button>
      </div>

      {/* Signature */}
      <div style={{ padding: '10px 14px', borderBottom: `1px solid ${theme.glass.borderColor}` }}>
        <pre style={{
          color: `rgba(${morph.mode === 'kleisli' ? theme.node.accentPurple : theme.node.accentBlue}, 0.9)`,
          fontSize: 10, lineHeight: 1.5, margin: 0, whiteSpace: 'pre-wrap',
          fontFamily: 'SF Mono, Menlo, monospace',
        }}>
          {sig}
        </pre>
      </div>

      {/* IN section */}
      <PortSection
        title="In"
        ports={morph.inputs}
        morphId={morphismId}
        side="input"
        onRename={renamePort}
        onAdd={addPort}
        onRemove={removePort}
      />

      {/* PARAM section */}
      <PortSection
        title="Param"
        ports={morph.paramInputs ?? []}
        morphId={morphismId}
        side="param"
        onRename={renamePort}
        onAdd={addPort}
        onRemove={removePort}
      />

      {/* OUT section */}
      <PortSection
        title="Out"
        ports={morph.outputs}
        morphId={morphismId}
        side="output"
        onRename={renamePort}
        onAdd={addPort}
        onRemove={removePort}
      />

      {/* Mode toggle */}
      <div style={{ padding: '8px 14px', borderTop: `1px solid ${theme.glass.borderColor}` }}>
        <div style={{ ...sectionLabelStyle, marginBottom: 6 }}>Mode</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {(['tarski', 'kleisli'] as const).map((m) => (
            <button
              key={m}
              onClick={() => updateMorphism(morphismId, { mode: m })}
              style={{
                ...smallBtnStyle,
                background: morph.mode === m
                  ? `rgba(${m === 'kleisli' ? theme.node.accentPurple : theme.node.accentBlue}, 0.3)`
                  : undefined,
                color: morph.mode === m ? theme.text.primary : theme.text.muted,
              }}
            >
              {m}
            </button>
          ))}
        </div>
      </div>

      {/* Instances */}
      <InstanceEditor
        instances={morph.instances}
        onChange={(instances) => updateMorphism(morphismId, { instances })}
      />

      {/* Delete */}
      <div style={{ padding: '8px 14px' }}>
        <button
          onClick={() => { removeMorphism(morphismId); onClose() }}
          style={{ ...smallBtnStyle, width: '100%', color: 'rgba(255,100,100,0.8)', borderColor: 'rgba(255,100,100,0.3)' }}
        >
          Delete
        </button>
      </div>
    </div>
  )
}

const sectionLabelStyle: React.CSSProperties = {
  color: theme.text.dimmed,
  fontSize: 9,
  textTransform: 'uppercase',
  letterSpacing: '0.05em',
}

function PortSection({ title, ports, morphId, side, onRename, onAdd, onRemove }: {
  title: string
  ports: PortDef[]
  morphId: string
  side: 'input' | 'output' | 'param'
  onRename: (morphId: string, portId: string, label: string) => void
  onAdd: (morphId: string, side: 'input' | 'output' | 'param') => void
  onRemove: (morphId: string, portId: string) => void
}) {
  return (
    <div style={{ padding: '8px 14px', borderBottom: `1px solid ${theme.glass.borderColor}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <div style={sectionLabelStyle}>{title}</div>
        <button
          onClick={() => onAdd(morphId, side)}
          style={{ ...tinyBtnStyle }}
          title={`Add ${title.toLowerCase()}`}
        >
          +
        </button>
      </div>
      {ports.length === 0 && (
        <div style={{ color: theme.text.dimmed, fontSize: 10, fontStyle: 'italic' }}>none</div>
      )}
      {ports.map((p) => (
        <div key={p.id} style={{ display: 'flex', gap: 4, marginBottom: 3, alignItems: 'center' }}>
          <input
            value={p.label}
            onChange={(e) => onRename(morphId, p.id, e.target.value)}
            placeholder="type name..."
            style={{ ...inputStyle, flex: 1, fontSize: 11, padding: '3px 6px' }}
          />
          <button
            onClick={() => onRemove(morphId, p.id)}
            style={tinyBtnStyle}
            title="Remove"
          >
            -
          </button>
        </div>
      ))}
    </div>
  )
}

function InstanceEditor({ instances, onChange }: { instances: InstanceDef[]; onChange: (i: InstanceDef[]) => void }) {
  return (
    <div style={{ padding: '8px 14px', borderBottom: `1px solid ${theme.glass.borderColor}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
        <div style={sectionLabelStyle}>Instances</div>
        <button onClick={() => onChange([...instances, { universe: '', def: '' }])} style={tinyBtnStyle}>+</button>
      </div>
      {instances.map((inst, i) => (
        <div key={i} style={{ marginBottom: 8 }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 3 }}>
            <input
              value={inst.universe}
              onChange={(e) => onChange(instances.map((x, j) => j === i ? { ...x, universe: e.target.value } : x))}
              placeholder="Universe"
              style={{ ...inputStyle, flex: 1, fontSize: 10, padding: '3px 6px' }}
            />
            <button onClick={() => onChange(instances.filter((_, j) => j !== i))} style={tinyBtnStyle}>-</button>
          </div>
          <textarea
            value={inst.def}
            onChange={(e) => onChange(instances.map((x, j) => j === i ? { ...x, def: e.target.value } : x))}
            placeholder="Implementation..."
            rows={2}
            style={{ ...inputStyle, fontFamily: 'SF Mono, Menlo, monospace', fontSize: 10, resize: 'vertical' as const }}
          />
        </div>
      ))}
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

const smallBtnStyle: React.CSSProperties = {
  padding: '4px 10px',
  fontSize: 11,
  borderRadius: 4,
  border: '1px solid rgba(255,255,255,0.08)',
  background: 'rgba(255,255,255,0.06)',
  color: 'rgba(255,255,255,0.8)',
  cursor: 'pointer',
}

const tinyBtnStyle: React.CSSProperties = {
  width: 18,
  height: 18,
  borderRadius: 4,
  border: '1px solid rgba(255,255,255,0.1)',
  background: 'rgba(255,255,255,0.04)',
  color: 'rgba(255,255,255,0.5)',
  fontSize: 12,
  lineHeight: '16px',
  textAlign: 'center',
  cursor: 'pointer',
  padding: 0,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  flexShrink: 0,
}
