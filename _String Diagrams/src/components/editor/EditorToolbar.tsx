import { useState, useMemo } from 'react'
import theme, { panelStyle } from '../../lib/theme'
import { useDiagramStore } from '../../store/diagramStore'
import { generateAllFiles } from '../../codegen'
import type { GeneratedFile } from '../../codegen'
import LogicPalette from './LogicPalette'
import CodePreview from './CodePreview'

export default function EditorToolbar() {
  const mode = useDiagramStore((s) => s.mode)
  const setMode = useDiagramStore((s) => s.setMode)
  const saveDiagram = useDiagramStore((s) => s.saveDiagram)
  const editorDiagram = useDiagramStore((s) => s.editorDiagram)

  const [showLogicPalette, setShowLogicPalette] = useState(false)
  const [generatedFiles, setGeneratedFiles] = useState<GeneratedFile[] | null>(null)

  function handleGenerate() {
    if (!editorDiagram || editorDiagram.morphisms.length === 0) return
    const files = generateAllFiles(editorDiagram)
    setGeneratedFiles(files)
  }

  const btnStyle = {
    padding: '4px 10px',
    fontSize: 11,
    borderRadius: 4,
    border: `1px solid ${theme.glass.borderColor}`,
    background: theme.glass.buttonBg,
    color: theme.text.secondary,
    cursor: 'pointer' as const,
  }

  const activeBtnStyle = {
    ...btnStyle,
    background: `rgba(${theme.node.accentIndigo}, 0.3)`,
    color: theme.text.primary,
  }

  return (
    <>
      <div
        style={{
          position: 'absolute',
          top: 12,
          left: 'var(--controls-left, 12px)',
          zIndex: 20,
          transition: 'left 0.25s ease',
          display: 'flex',
          gap: 4,
          alignItems: 'center',
        }}
      >
        {/* Mode toggle */}
        <div className="sd-toolbar-group" style={{ marginRight: 8 }}>
          <button
            className="sd-toolbar-btn"
            onClick={() => setMode(mode === 'view' ? 'edit' : 'view')}
            style={{
              color: mode === 'edit' ? theme.text.primary : theme.text.dimmed,
              fontSize: 11,
              padding: '0 10px',
            }}
          >
            {mode === 'edit' ? 'Editing' : 'View'}
          </button>
        </div>

        {mode === 'edit' && (
          <>
            <button style={btnStyle} onClick={() => setShowLogicPalette(true)}>
              + Logical
            </button>
            <button style={activeBtnStyle} onClick={() => { saveDiagram(); setMode('view'); }}>
              Save
            </button>
            <button style={activeBtnStyle} onClick={handleGenerate}>
              Generate
            </button>
          </>
        )}
      </div>

      {showLogicPalette && (
        <Overlay onClose={() => setShowLogicPalette(false)}>
          <LogicPalette onClose={() => setShowLogicPalette(false)} />
        </Overlay>
      )}

      {generatedFiles && (
        <CodePreview
          files={generatedFiles}
          onClose={() => setGeneratedFiles(null)}
        />
      )}
    </>
  )
}

function Overlay({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.4)',
        zIndex: 100,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
      onClick={(e) => { if (e.target === e.currentTarget) onClose() }}
    >
      {children}
    </div>
  )
}

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '6px 10px',
  fontSize: 12,
  borderRadius: 4,
  border: '1px solid rgba(255,255,255,0.1)',
  background: 'rgba(255,255,255,0.04)',
  color: '#fff',
  outline: 'none',
  fontFamily: 'inherit',
  boxSizing: 'border-box',
}
