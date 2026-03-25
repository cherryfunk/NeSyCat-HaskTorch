import theme, { panelStyle, buttonStyle } from '../lib/theme'

interface Instance {
  universe: string
  def: string
}

interface PortInfo {
  id: string
  label: string
  position: string
}

interface NodeDetailProps {
  label: string
  haskellSig: string
  haskellClass: string
  instances: Instance[]
  mode: string
  inputs?: PortInfo[]
  outputs?: PortInfo[]
  paramInputs?: PortInfo[]
  onClose: () => void
}

function buildSigFromPorts(
  label: string,
  inputs: PortInfo[],
  outputs: PortInfo[],
  paramInputs: PortInfo[],
  mode: string,
): string {
  const parts: string[] = []
  for (const p of paramInputs) parts.push(p.label)
  for (const p of inputs) parts.push(p.label)
  if (outputs.length > 0) {
    const out = outputs[0].label
    parts.push(mode === 'kleisli' ? `M U (${out})` : out)
  }
  return `${label} :: ${parts.join(' -> ')}`
}

export default function NodeDetail({
  label, haskellSig, haskellClass, instances, mode,
  inputs, outputs, paramInputs, onClose,
}: NodeDetailProps) {
  const sig = haskellSig || buildSigFromPorts(
    label,
    inputs ?? [],
    outputs ?? [],
    paramInputs ?? [],
    mode,
  )

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
          <div
            style={{
              fontWeight: 700,
              fontSize: 13,
              color: theme.text.primary,
              textShadow: theme.text.shadow,
            }}
          >
            {label}
          </div>
          <div style={{ fontSize: 10, color: theme.text.dimmed, marginTop: 2 }}>
            {mode}{haskellClass ? ` \u00b7 class ${haskellClass}` : ''}
          </div>
        </div>
        <button
          onClick={onClose}
          style={{
            ...buttonStyle(),
            borderRadius: 4,
            fontSize: 12,
            cursor: 'pointer',
            padding: '1px 6px',
            flexShrink: 0,
          }}
        >
          x
        </button>
      </div>

      {/* Type signature */}
      {sig && (
        <div style={{ padding: '10px 14px', borderBottom: `1px solid ${theme.glass.borderColor}` }}>
          <pre
            style={{
              color: `rgba(${mode === 'kleisli' ? theme.node.accentPurple : theme.node.accentBlue}, 0.9)`,
              fontSize: 10,
              lineHeight: 1.5,
              margin: 0,
              whiteSpace: 'pre-wrap',
              fontFamily: 'SF Mono, Menlo, monospace',
            }}
          >
            {sig}
          </pre>
        </div>
      )}

      {/* Instances */}
      {instances.length > 0 && instances.map((inst, i) => (
        <div
          key={i}
          style={{
            padding: '8px 14px',
            borderBottom: i < instances.length - 1 ? `1px solid ${theme.glass.borderColor}` : 'none',
          }}
        >
          <div style={{ color: theme.text.dimmed, fontSize: 9, marginBottom: 4, textTransform: 'uppercase' as const, letterSpacing: '0.05em' }}>
            {inst.universe}
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
            {inst.def}
          </pre>
        </div>
      ))}
    </div>
  )
}
