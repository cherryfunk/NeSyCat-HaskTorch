import { memo } from 'react'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import theme, { glassBlur } from '../lib/theme'
import type { PortDef } from '../model/types'

interface MorphismData {
  label: string
  haskellSig: string
  category: string
  accent: string
  inputs: PortDef[]
  outputs: PortDef[]
}

function MorphismNode({ data }: NodeProps) {
  const d = data as unknown as MorphismData
  const fillOpacity = theme.node.fillOpacity
  const borderOpacity = theme.node.borderOpacity

  return (
    <div
      style={{
        background: `rgba(${d.accent}, ${fillOpacity})`,
        border: `1px solid rgba(${d.accent}, ${borderOpacity})`,
        borderRadius: 6,
        padding: '8px 14px',
        minWidth: 100,
        textAlign: 'center',
        ...glassBlur(),
      }}
    >
      <div style={{ color: theme.text.primary, fontSize: 13, fontWeight: 600 }}>
        {d.label}
      </div>
      <div style={{ color: theme.text.dimmed, fontSize: 10, marginTop: 2 }}>
        {d.haskellSig}
      </div>

      {d.inputs.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="target"
          position={Position.Left}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.inputs.length + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.6)`,
            width: 8,
            height: 8,
            border: 'none',
          }}
        />
      ))}

      {d.outputs.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="source"
          position={Position.Right}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.outputs.length + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.6)`,
            width: 8,
            height: 8,
            border: 'none',
          }}
        />
      ))}
    </div>
  )
}

export default memo(MorphismNode)
