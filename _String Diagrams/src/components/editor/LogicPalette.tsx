import theme, { panelStyle } from '../../lib/theme'
import { useDiagramStore } from '../../store/diagramStore'
import { LOGIC_PALETTE } from '../../model/logicPalette'
import type { MorphismDef, PortDef } from '../../model/types'

interface Props {
  onClose: () => void
}

export default function LogicPalette({ onClose }: Props) {
  const addMorphism = useDiagramStore((s) => s.addMorphism)

  function instantiate(template: Omit<MorphismDef, 'id'>) {
    const id = `${template.label}-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
    // Create unique port IDs
    const reIdPort = (p: PortDef, prefix: string, i: number): PortDef => ({
      ...p,
      id: `${id}-${prefix}-${i}`,
    })
    const morph: MorphismDef = {
      ...template,
      id,
      inputs: template.inputs.map((p, i) => reIdPort(p, 'in', i)),
      outputs: template.outputs.map((p, i) => reIdPort(p, 'out', i)),
      paramInputs: template.paramInputs?.map((p, i) => reIdPort(p, 'param', i)),
    }
    addMorphism(morph)
    onClose()
  }

  return (
    <div style={{ ...panelStyle(), borderRadius: 12, padding: 16, width: 300, maxHeight: '70vh', overflow: 'auto' }}>
      <div style={{ color: theme.text.primary, fontSize: 13, fontWeight: 600, marginBottom: 12 }}>
        Add Logical Operation
      </div>

      {LOGIC_PALETTE.map((op, i) => (
        <button
          key={i}
          onClick={() => instantiate(op)}
          style={{
            display: 'block',
            width: '100%',
            textAlign: 'left',
            padding: '8px 12px',
            marginBottom: 4,
            borderRadius: 6,
            border: `1px solid ${theme.glass.borderColor}`,
            background: 'transparent',
            cursor: 'pointer',
          }}
        >
          <div style={{ color: theme.text.secondary, fontSize: 12, fontWeight: 500 }}>
            {op.label}
          </div>
          <div style={{ color: theme.text.dimmed, fontSize: 10, marginTop: 2, fontFamily: 'SF Mono, Menlo, monospace' }}>
            {op.haskellSig}
          </div>
        </button>
      ))}
    </div>
  )
}
