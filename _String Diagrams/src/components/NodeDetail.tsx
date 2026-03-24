import theme, { panelStyle, buttonStyle } from '../lib/theme'

interface NodeDetailProps {
  label: string
  haskellSig: string
  haskellDef: string
  mode: string
  onClose: () => void
}

function InfoRow({ label, value, mono, last }: { label: string; value: string; mono?: boolean; last?: boolean }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        padding: '3px 0',
        fontSize: 11,
        borderBottom: last ? 'none' : `1px solid ${theme.glass.borderColor}`,
      }}
    >
      <span style={{ color: theme.text.muted, textShadow: theme.text.shadowLight }}>{label}</span>
      <span
        style={{
          color: theme.text.secondary,
          textShadow: theme.text.shadowLight,
          fontFamily: mono ? 'SF Mono, Menlo, monospace' : 'inherit',
          fontSize: mono ? 9 : 11,
          maxWidth: 180,
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}
      >
        {value}
      </span>
    </div>
  )
}

export default function NodeDetail({ label, haskellSig, haskellDef, mode, onClose }: NodeDetailProps) {
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
        <div
          style={{
            fontWeight: 700,
            fontSize: 13,
            color: theme.text.primary,
            textShadow: theme.text.shadow,
            flex: 1,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {label}
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

      {/* Info rows */}
      <div style={{ padding: '8px 14px 6px' }}>
        <InfoRow label="Mode" value={mode} last />
      </div>

      {/* Type signature */}
      <div style={{ padding: '8px 14px 6px', borderTop: `1px solid ${theme.glass.borderColor}` }}>
        <div style={{ color: theme.text.dimmed, fontSize: 10, marginBottom: 4 }}>
          Type signature
        </div>
        <pre
          style={{
            color: `rgba(${theme.node.accentBlue}, 0.9)`,
            fontSize: 10,
            lineHeight: 1.5,
            margin: 0,
            whiteSpace: 'pre-wrap',
            fontFamily: 'SF Mono, Menlo, monospace',
          }}
        >
          {haskellSig}
        </pre>
      </div>

      {/* Definition */}
      <div style={{ padding: '8px 14px 10px', borderTop: `1px solid ${theme.glass.borderColor}` }}>
        <div style={{ color: theme.text.dimmed, fontSize: 10, marginBottom: 4 }}>
          Definition
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
          {haskellDef}
        </pre>
      </div>
    </div>
  )
}
