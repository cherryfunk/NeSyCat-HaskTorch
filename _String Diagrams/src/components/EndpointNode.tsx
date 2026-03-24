import { memo } from 'react'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import theme from '../lib/theme'

interface EndpointData {
  label: string
  wireType: string
  side: 'input' | 'output'
}

function EndpointNode({ data, id }: NodeProps) {
  const d = data as unknown as EndpointData
  const isInput = d.side === 'input'

  return (
    <div
      style={{
        padding: '4px 12px',
        borderRadius: 4,
        background: 'rgba(255,255,255,0.04)',
        border: `1px solid rgba(255,255,255,0.1)`,
        textAlign: 'center',
      }}
    >
      <div style={{ color: theme.text.muted, fontSize: 11, fontWeight: 500 }}>
        {d.label}
      </div>

      {isInput ? (
        <Handle
          type="source"
          position={Position.Right}
          id={id}
          style={{
            top: '50%',
            background: 'rgba(255,255,255,0.3)',
            width: 7,
            height: 7,
            border: 'none',
          }}
        />
      ) : (
        <Handle
          type="target"
          position={Position.Left}
          id={id}
          style={{
            top: '50%',
            background: 'rgba(255,255,255,0.3)',
            width: 7,
            height: 7,
            border: 'none',
          }}
        />
      )}
    </div>
  )
}

export default memo(EndpointNode)
