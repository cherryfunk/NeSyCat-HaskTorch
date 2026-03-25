import { memo } from 'react'
import type { NodeProps } from '@xyflow/react'
import theme from '../lib/theme'
import { useDiagramStore } from '../store/diagramStore'

interface WallData {
  height: number
}

function WallNode({ data }: NodeProps) {
  const d = data as unknown as WallData
  const storeMode = useDiagramStore((s) => s.mode)
  const addVariable = useDiagramStore((s) => s.addVariable)
  const isEditMode = storeMode === 'edit'

  return (
    <div
      style={{
        width: 2,
        height: d.height || 400,
        background: 'rgba(255,255,255,0.08)',
        position: 'relative',
        cursor: 'grab',
      }}
    >
      {/* + button at the bottom */}
      {isEditMode && (
        <button
          onMouseDown={(e) => e.stopPropagation()}
          onClick={(e) => {
            e.stopPropagation()
            e.preventDefault()
            addVariable()
          }}
          style={{
            position: 'absolute',
            bottom: -24,
            left: '50%',
            transform: 'translateX(-50%)',
            width: 20,
            height: 20,
            borderRadius: '50%',
            border: `1px solid ${theme.glass.borderColor}`,
            background: theme.glass.buttonBg,
            color: theme.text.muted,
            fontSize: 14,
            lineHeight: '18px',
            textAlign: 'center',
            cursor: 'pointer',
            padding: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
          title="Add variable"
        >
          +
        </button>
      )}
    </div>
  )
}

export default memo(WallNode)
