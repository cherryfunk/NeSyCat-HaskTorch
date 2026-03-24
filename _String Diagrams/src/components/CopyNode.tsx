import { memo } from 'react'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import theme from '../lib/theme'
import type { PortDef } from '../model/types'

interface CopyData {
  wireType: string
  input: PortDef
  outputs: PortDef[]
}

function CopyNode({ data }: NodeProps) {
  const d = data as unknown as CopyData
  const accent = d.wireType === 'ParamsLogic' || d.wireType === 'ParamsMLP'
    ? theme.node.accentIndigo
    : theme.node.accentBlue

  return (
    <div
      style={{
        width: 16,
        height: 16,
        borderRadius: '50%',
        background: `rgba(${accent}, 0.5)`,
        border: `1px solid rgba(${accent}, 0.7)`,
        position: 'relative',
      }}
    >
      <Handle
        type="target"
        position={Position.Left}
        id={d.input.id}
        style={{
          top: '50%',
          background: `rgba(${accent}, 0.6)`,
          width: 6,
          height: 6,
          border: 'none',
        }}
      />
      {d.outputs.map((port: PortDef, i: number) => (
        <Handle
          key={port.id}
          type="source"
          position={Position.Right}
          id={port.id}
          style={{
            top: `${((i + 1) / (d.outputs.length + 1)) * 100}%`,
            background: `rgba(${accent}, 0.6)`,
            width: 6,
            height: 6,
            border: 'none',
          }}
        />
      ))}
    </div>
  )
}

export default memo(CopyNode)
