import { useMemo, useState } from 'react'
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  BackgroundVariant,
} from '@xyflow/react'
import type { StringDiagram } from '../model/types'
import { layoutDiagram } from '../lib/layout'
import theme from '../lib/theme'
import MorphismNode from './MorphismNode'
import CopyNode from './CopyNode'
import EndpointNode from './EndpointNode'

const nodeTypes = {
  morphismBox: MorphismNode,
  copyPoint: CopyNode,
  endpoint: EndpointNode,
}

type MinimapMode = 'always' | 'hover' | 'hidden'

interface Props {
  diagram: StringDiagram
}

export default function DiagramCanvas({ diagram }: Props) {
  const [minimapMode, setMinimapMode] = useState<MinimapMode>('always')
  const { nodes, edges } = useMemo(() => layoutDiagram(diagram), [diagram])

  const minimapClass = minimapMode === 'hover' ? 'minimap-hover' : ''

  return (
    <div style={{ width: '100%', height: '100%' }} className={minimapClass}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        fitView
        nodesDraggable={false}
        nodesConnectable={false}
        elementsSelectable={true}
        proOptions={{ hideAttribution: true }}
      >
        <Background
          variant={BackgroundVariant.Dots}
          gap={20}
          size={1}
          color={theme.canvas.gridColor}
        />
        <Controls />
        {minimapMode !== 'hidden' && (
          <MiniMap
            nodeColor={(node) => {
              const cat = (node.data as Record<string, unknown>)?.category as string | undefined
              if (cat === 'pure') return `rgba(${theme.node.accentBlue}, 0.8)`
              if (cat === 'kleisli') return `rgba(${theme.node.accentPurple}, 0.8)`
              if (cat === 'logic') return `rgba(${theme.node.accentIndigo}, 0.8)`
              return 'rgba(255,255,255,0.3)'
            }}
            maskColor={theme.minimap.maskColor}
            nodeStrokeWidth={0}
            pannable
            zoomable
          />
        )}
      </ReactFlow>

      {/* Minimap mode toggle */}
      <div
        style={{
          position: 'absolute',
          bottom: 12,
          right: 12,
          display: 'flex',
          gap: 4,
          zIndex: 10,
        }}
      >
        {(['always', 'hover', 'hidden'] as MinimapMode[]).map((mode) => (
          <button
            key={mode}
            onClick={() => setMinimapMode(mode)}
            style={{
              padding: '3px 8px',
              fontSize: 10,
              borderRadius: 4,
              border: `1px solid ${theme.glass.borderColor}`,
              background: minimapMode === mode
                ? `rgba(${theme.node.accentIndigo}, 0.3)`
                : theme.glass.buttonBg,
              color: theme.text.muted,
              cursor: 'pointer',
            }}
          >
            {mode}
          </button>
        ))}
      </div>
    </div>
  )
}
