import { memo } from 'react'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import theme, { glassBlur } from '../lib/theme'
import type { PortDef } from '../model/types'

interface MorphismData {
  label: string
  haskellSig: string
  haskellDef: string
  mode: string
  accent: string
  inputs: PortDef[]
  outputs: PortDef[]
  paramInputs: PortDef[]
}

function MorphismNode({ data, selected }: NodeProps) {
  const d = data as unknown as MorphismData
  const params = d.paramInputs ?? []

  const fillOpacity = selected
    ? theme.node.selectedFillOpacity
    : theme.node.fillOpacity
  const borderOpacity = selected
    ? theme.node.selectedBorderOpacity
    : theme.node.borderOpacity

  return (
    <div
      style={{
        background: `rgba(${d.accent}, ${fillOpacity})`,
        border: `1px solid rgba(${d.accent}, ${borderOpacity})`,
        borderRadius: 8,
        padding: '8px 16px',
        minWidth: 70,
        textAlign: 'center',
        cursor: 'pointer',
        ...glassBlur(),
        boxShadow: selected
          ? `0 0 0 1px rgba(${d.accent},0.4), 0 4px 12px rgba(0,0,0,0.3)`
          : '0 1px 4px rgba(0,0,0,0.2)',
        transition: 'all 0.15s ease',
      }}
    >
      <div
        style={{
          fontWeight: 600,
          fontSize: 13,
          color: theme.text.primary,
          textShadow: theme.text.shadowLight,
          lineHeight: '1.3',
        }}
      >
        {d.label}
      </div>

      {/* Left-side data inputs */}
      {d.inputs.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="target"
          position={Position.Left}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.inputs.length + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.8)`,
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}

      {/* Top-side parameter inputs */}
      {params.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="target"
          position={Position.Top}
          id={port.id}
          style={{
            left: `${((i + 1) / (params.length + 1)) * 100}%`,
            background: 'rgba(255,255,255,0.2)',
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}

      {/* Right-side outputs */}
      {d.outputs.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="source"
          position={Position.Right}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.outputs.length + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.8)`,
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}
    </div>
  )
}

export default memo(MorphismNode)
