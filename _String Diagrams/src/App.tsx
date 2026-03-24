import { useState, useCallback } from 'react'
import { ReactFlowProvider } from '@xyflow/react'
import DiagramCanvas from './components/DiagramCanvas'
import Sidebar from './components/Sidebar'
import { binaryPredicateDiagram } from './model/diagrams/binaryPredicate'
import { binarySentenceDiagram } from './model/diagrams/binarySentence'
import type { StringDiagram } from './model/types'

const SIDEBAR_WIDTH = 240

const allDiagrams: StringDiagram[] = [
  binaryPredicateDiagram,
  binarySentenceDiagram,
]

export default function App() {
  const [activeId, setActiveId] = useState(allDiagrams[0].id)
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const activeDiagram = allDiagrams.find((d) => d.id === activeId) ?? allDiagrams[0]

  const sidebarWidth = sidebarOpen ? SIDEBAR_WIDTH : 0

  const toggleSidebar = useCallback(() => {
    setSidebarOpen((prev) => {
      const next = !prev
      const root = document.documentElement
      root.style.setProperty('--controls-left', `${(next ? SIDEBAR_WIDTH : 0) + 12}px`)
      return next
    })
  }, [])

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
