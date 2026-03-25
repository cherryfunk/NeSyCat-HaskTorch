import { useState } from 'react'
import theme, { panelStyle, buttonStyle as themeBtnStyle } from '../../lib/theme'
import type { GeneratedFile } from '../../codegen'
import { writeGeneratedFiles } from '../../lib/api'

interface Props {
  files: GeneratedFile[]
  onClose: () => void
}

export default function CodePreview({ files, onClose }: Props) {
  const [activeTab, setActiveTab] = useState(0)
  const [status, setStatus] = useState<'idle' | 'writing' | 'success' | 'error'>('idle')
  const [errorMsg, setErrorMsg] = useState('')

  async function handleWrite() {
    setStatus('writing')
    const result = await writeGeneratedFiles(files)
    if (result.success) {
      setStatus('success')
    } else {
      setStatus('error')
      setErrorMsg(result.error ?? 'Unknown error')
    }
  }

  const active = files[activeTab]

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.5)',
        zIndex: 100,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
      onClick={(e) => { if (e.target === e.currentTarget) onClose() }}
    >
      <div
        style={{
          ...panelStyle(),
          borderRadius: 12,
          width: 600,
          maxHeight: '80vh',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
        }}
      >
        {/* Header */}
        <div style={{ padding: '12px 16px', borderBottom: `1px solid ${theme.glass.borderColor}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ color: theme.text.primary, fontSize: 14, fontWeight: 600 }}>
            Generated Haskell
          </div>
          <button onClick={onClose} style={{ ...themeBtnStyle(), borderRadius: 4, fontSize: 12, cursor: 'pointer', padding: '1px 6px' }}>
            x
          </button>
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', borderBottom: `1px solid ${theme.glass.borderColor}`, padding: '0 16px' }}>
          {files.map((f, i) => {
            const filename = f.path.split('/').pop() ?? f.path
            const isActive = i === activeTab
            return (
              <button
                key={i}
                onClick={() => setActiveTab(i)}
                style={{
                  padding: '8px 12px',
                  fontSize: 11,
                  border: 'none',
                  borderBottom: isActive ? `2px solid rgba(${theme.node.accentIndigo}, 0.8)` : '2px solid transparent',
                  background: 'transparent',
                  color: isActive ? theme.text.primary : theme.text.dimmed,
                  cursor: 'pointer',
                }}
              >
                {filename}
              </button>
            )
          })}
        </div>

        {/* File path */}
        {active && (
          <div style={{ padding: '8px 16px', color: theme.text.dimmed, fontSize: 10, fontFamily: 'SF Mono, Menlo, monospace' }}>
            {active.path}
          </div>
        )}

        {/* Code */}
        <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 16px' }}>
          {active && (
            <pre
              style={{
                color: theme.text.muted,
                fontSize: 11,
                lineHeight: 1.6,
                margin: 0,
                whiteSpace: 'pre-wrap',
                fontFamily: 'SF Mono, Menlo, monospace',
              }}
            >
              {active.content}
            </pre>
          )}
        </div>

        {/* Actions */}
        <div style={{ padding: '12px 16px', borderTop: `1px solid ${theme.glass.borderColor}`, display: 'flex', gap: 8, alignItems: 'center' }}>
          {status === 'success' ? (
            <div style={{ color: 'rgba(100,255,100,0.8)', fontSize: 12 }}>
              Written {files.length} files to repo
            </div>
          ) : status === 'error' ? (
            <div style={{ color: 'rgba(255,100,100,0.8)', fontSize: 12 }}>
              Error: {errorMsg}
            </div>
          ) : null}
          <div style={{ flex: 1 }} />
          <button
            onClick={handleWrite}
            disabled={status === 'writing' || status === 'success'}
            style={{
              padding: '6px 16px',
              fontSize: 12,
              borderRadius: 6,
              border: `1px solid rgba(${theme.node.accentIndigo}, 0.5)`,
              background: `rgba(${theme.node.accentIndigo}, 0.3)`,
              color: theme.text.primary,
              cursor: status === 'writing' || status === 'success' ? 'default' : 'pointer',
              opacity: status === 'writing' || status === 'success' ? 0.5 : 1,
            }}
          >
            {status === 'writing' ? 'Writing...' : status === 'success' ? 'Done' : 'Write to Repo'}
          </button>
        </div>
      </div>
    </div>
  )
}
