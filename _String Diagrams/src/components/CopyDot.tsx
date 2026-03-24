import { memo } from 'react'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'

interface CopyDotData {
  accent: string
  outputCount: number
}

function CopyDot({ data }: NodeProps) {
  const d = data as unknown as CopyDotData

  return (
    <div
      style={{
        width: 28,
        height: 28,
        borderRadius: '50%',
        background: `rgba(${d.accent}, 0.15)`,
        border: `1.5px solid rgba(${d.accent}, 0.5)`,
      }}
    >
      <Handle
        type="target"
        position={Position.Left}
        id="in"
        style={{
          background: `rgba(${d.accent}, 0.8)`,
          width: 5,
          height: 5,
          border: 'none',
        }}
      />

      {Array.from({ length: d.outputCount }, (_, i) => (
        <Handle
          key={i}
          type="source"
          position={Position.Right}
          id={`out-${i}`}
          style={{
            top: d.outputCount === 1
              ? '50%'
              : `${((i + 1) / (d.outputCount + 1)) * 100}%`,
            background: `rgba(${d.accent}, 0.8)`,
            width: 5,
            height: 5,
            border: 'none',
          }}
        />
      ))}
    </div>
  )
}

export default memo(CopyDot)
