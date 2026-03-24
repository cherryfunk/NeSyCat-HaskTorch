import { useState } from 'react'
import { ReactFlowProvider } from '@xyflow/react'
import DiagramCanvas from './components/DiagramCanvas'
import Sidebar from './components/Sidebar'
import { binaryPredicateDiagram } from './model/diagrams/binaryPredicate'
import { binarySentenceDiagram } from './model/diagrams/binarySentence'
import type { StringDiagram } from './model/types'

const allDiagrams: StringDiagram[] = [
  binaryPredicateDiagram,
  binarySentenceDiagram,
]

export default function App() {
  const [activeId, setActiveId] = useState(allDiagrams[0].id)
  const activeDiagram = allDiagrams.find((d) => d.id === activeId) ?? allDiagrams[0]

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative' }}>
      <ReactFlowProvider>
        <DiagramCanvas diagram={activeDiagram} />
        <Sidebar
          diagrams={allDiagrams}
          activeDiagram={activeId}
          onSelect={setActiveId}
        />
      </ReactFlowProvider>
    </div>
  )
}
