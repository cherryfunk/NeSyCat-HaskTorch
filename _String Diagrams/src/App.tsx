import { useState, useCallback, useMemo } from 'react'
import { ReactFlowProvider } from '@xyflow/react'
import DiagramCanvas from './components/DiagramCanvas'
import Sidebar from './components/Sidebar'
import { useDiagramStore } from './store/diagramStore'

const SIDEBAR_WIDTH = 240

export default function App() {
  const activeId = useDiagramStore((s) => s.activeId)
  const setActiveId = useDiagramStore((s) => s.setActiveId)
  const mode = useDiagramStore((s) => s.mode)
  const editorDiagram = useDiagramStore((s) => s.editorDiagram)
  const builtins = useDiagramStore((s) => s.builtinDiagrams)
  const userDiagrams = useDiagramStore((s) => s.userDiagrams)

  const allDiagrams = useMemo(() => {
    const list = [...builtins, ...userDiagrams]
    // Include the editor diagram if it's new (not yet saved to userDiagrams)
    if (editorDiagram && !list.some((d) => d.id === editorDiagram.id)) {
      list.push(editorDiagram)
    }
    return list
  }, [builtins, userDiagrams, editorDiagram])

  const activeDiagram = useMemo(() => {
    if (mode === 'edit' && editorDiagram) return editorDiagram
    return allDiagrams.find((d) => d.id === activeId)
  }, [mode, editorDiagram, allDiagrams, activeId])

  const [sidebarOpen, setSidebarOpen] = useState(true)
  const sidebarWidth = sidebarOpen ? SIDEBAR_WIDTH : 0

  const toggleSidebar = useCallback(() => {
    setSidebarOpen((prev) => {
      const next = !prev
      document.documentElement.style.setProperty(
        '--controls-left',
        `${(next ? SIDEBAR_WIDTH : 0) + 12}px`
      )
      return next
    })
  }, [])

  if (!activeDiagram) return null

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative' }}>
      <ReactFlowProvider>
        <DiagramCanvas diagram={activeDiagram} sidebarWidth={sidebarWidth} />
        <Sidebar
          diagrams={allDiagrams}
          activeDiagram={activeId}
          onSelect={setActiveId}
          open={sidebarOpen}
          onToggle={toggleSidebar}
        />
      </ReactFlowProvider>
    </div>
  )
}
