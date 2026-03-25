import { create } from 'zustand'
import type { StringDiagram, MorphismDef, WireDef, DiagramEndpoint, PortDef } from '../model/types'
import { binaryPredicateDiagram } from '../model/diagrams/binaryPredicate'
import { binarySentenceDiagram } from '../model/diagrams/binarySentence'

const STORAGE_KEY = 'sd-user-diagrams'

function loadUserDiagrams(): StringDiagram[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}

function saveUserDiagrams(diagrams: StringDiagram[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(diagrams))
}

const builtinDiagrams: StringDiagram[] = [
  binaryPredicateDiagram,
  binarySentenceDiagram,
]

let idCounter = 0
function uniqueId(prefix: string): string {
  return `${prefix}-${Date.now()}-${idCounter++}`
}

interface DiagramStore {
  // All diagrams (builtin + user-created)
  builtinDiagrams: StringDiagram[]
  userDiagrams: StringDiagram[]
  activeId: string
  mode: 'view' | 'edit'

  // The diagram being edited (a mutable copy)
  editorDiagram: StringDiagram | null
  selectedNodeId: string | null

  // Getters
  allDiagrams: () => StringDiagram[]
  activeDiagram: () => StringDiagram | undefined

  // Mode
  setMode: (mode: 'view' | 'edit') => void
  setActiveId: (id: string) => void

  // Create new diagram
  createNewDiagram: (name: string) => void

  // Editor actions (mutate editorDiagram)
  updateEditorTitle: (title: string) => void
  addMorphismAtPosition: (x: number, y: number) => string // returns new morph id
  addPortToMorphism: (morphId: string, side: 'input' | 'output' | 'param') => void
  removePortFromMorphism: (morphId: string, portId: string) => void
  renamePort: (morphId: string, portId: string, label: string) => void
  renameMorphism: (morphId: string, name: string) => void
  addMorphism: (morph: MorphismDef) => void
  removeMorphism: (id: string) => void
  updateMorphism: (id: string, patch: Partial<MorphismDef>) => void
  addWire: (wire: WireDef) => void
  removeWire: (id: string) => void
  addInput: (ep: DiagramEndpoint) => void
  addOutput: (ep: DiagramEndpoint) => void
  removeInput: (id: string) => void
  removeOutput: (id: string) => void
  setSelectedNode: (id: string | null) => void

  // Save editor diagram back to userDiagrams
  saveDiagram: () => void

  // Load existing diagram into editor
  loadIntoEditor: (id: string) => void

  // Export/Import
  exportDiagramJSON: () => string | null
  importDiagramJSON: (json: string) => void
}

export const useDiagramStore = create<DiagramStore>((set, get) => ({
  builtinDiagrams,
  userDiagrams: loadUserDiagrams(),
  activeId: builtinDiagrams[0].id,
  mode: 'view',
  editorDiagram: null,
  selectedNodeId: null,

  allDiagrams: () => [...get().builtinDiagrams, ...get().userDiagrams],

  activeDiagram: () => {
    const { mode, editorDiagram, activeId } = get()
    if (mode === 'edit' && editorDiagram) return editorDiagram
    return get().allDiagrams().find((d) => d.id === activeId)
  },

  setMode: (mode) => {
    if (mode === 'edit') {
      const s = get()
      // Auto-load the active diagram into editor if not already loaded
      if (!s.editorDiagram || s.editorDiagram.id !== s.activeId) {
        const all = [...s.builtinDiagrams, ...s.userDiagrams]
        const diagram = all.find((d) => d.id === s.activeId)
        if (diagram) {
          set({ mode, editorDiagram: JSON.parse(JSON.stringify(diagram)) })
          return
        }
      }
    }
    set({ mode })
  },
  setActiveId: (id) => set({ activeId: id, selectedNodeId: null }),

  createNewDiagram: (name) => {
    const id = uniqueId('diagram')
    const diagram: StringDiagram = {
      id,
      title: name,
      description: '',
      haskellSource: '',
      morphisms: [],
      copies: [],
      wires: [],
      inputs: [],
      outputs: [],
    }
    set({ editorDiagram: diagram, activeId: id, mode: 'edit', selectedNodeId: null })
  },

  updateEditorTitle: (title) => set((s) => {
    if (!s.editorDiagram) return s
    return { editorDiagram: { ...s.editorDiagram, title } }
  }),

  addMorphismAtPosition: (x, y) => {
    const id = uniqueId('morph')
    set((s) => {
      if (!s.editorDiagram) return s
      const morph: MorphismDef = {
        id,
        label: 'f',
        haskellSig: '',
        haskellClass: '',
        instances: [],
        mode: 'tarski',
        layer: 'domain',
        inputs: [{ id: `${id}-in-0`, label: '', position: 'left' }],
        outputs: [{ id: `${id}-out-0`, label: '', position: 'right' }],
      }
      return {
        editorDiagram: {
          ...s.editorDiagram,
          morphisms: [...s.editorDiagram.morphisms, morph],
        },
        selectedNodeId: id,
      }
    })
    return id
  },

  addPortToMorphism: (morphId, side) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: s.editorDiagram.morphisms.map((m) => {
          if (m.id !== morphId) return m
          const suffix = side === 'input' ? 'in' : side === 'output' ? 'out' : 'param'
          const idx = side === 'input' ? m.inputs.length
            : side === 'output' ? m.outputs.length
            : (m.paramInputs?.length ?? 0)
          const portId = `${morphId}-${suffix}-${idx}`
          const pos = side === 'param' ? 'top' : side === 'input' ? 'left' : 'right'
          const port = { id: portId, label: '', position: pos as 'left' | 'right' | 'top' }
          if (side === 'input') return { ...m, inputs: [...m.inputs, port] }
          if (side === 'output') return { ...m, outputs: [...m.outputs, port] }
          return { ...m, paramInputs: [...(m.paramInputs ?? []), port] }
        }),
      },
    }
  }),

  removePortFromMorphism: (morphId, portId) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: s.editorDiagram.morphisms.map((m) => {
          if (m.id !== morphId) return m
          return {
            ...m,
            inputs: m.inputs.filter((p) => p.id !== portId),
            outputs: m.outputs.filter((p) => p.id !== portId),
            paramInputs: m.paramInputs?.filter((p) => p.id !== portId),
          }
        }),
        // Also remove wires connected to this port
        wires: s.editorDiagram.wires.filter(
          (w) => w.sourcePort !== portId && w.targetPort !== portId
        ),
      },
    }
  }),

  renamePort: (morphId, portId, label) => set((s) => {
    if (!s.editorDiagram) return s
    const renameIn = (p: PortDef): PortDef =>
      p.id === portId ? { ...p, label } : p
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: s.editorDiagram.morphisms.map((m) => {
          if (m.id !== morphId) return m
          return {
            ...m,
            inputs: m.inputs.map(renameIn),
            outputs: m.outputs.map(renameIn),
            paramInputs: m.paramInputs?.map(renameIn),
          }
        }),
      },
    }
  }),

  renameMorphism: (morphId, name) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: s.editorDiagram.morphisms.map((m) =>
          m.id === morphId ? { ...m, label: name } : m
        ),
      },
    }
  }),

  addMorphism: (morph) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: [...s.editorDiagram.morphisms, morph],
      },
    }
  }),

  removeMorphism: (id) => set((s) => {
    if (!s.editorDiagram) return s
    const before = s.editorDiagram.morphisms.length
    const after = s.editorDiagram.morphisms.filter((m) => m.id !== id).length
    console.log('[REMOVE] morphism', id, 'before:', before, 'after:', after)
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: s.editorDiagram.morphisms.filter((m) => m.id !== id),
        // Also remove wires connected to this morphism
        wires: s.editorDiagram.wires.filter(
          (w) => w.sourceBox !== id && w.targetBox !== id
        ),
      },
      selectedNodeId: s.selectedNodeId === id ? null : s.selectedNodeId,
    }
  }),

  updateMorphism: (id, patch) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        morphisms: s.editorDiagram.morphisms.map((m) =>
          m.id === id ? { ...m, ...patch } : m
        ),
      },
    }
  }),

  addWire: (wire) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        wires: [...s.editorDiagram.wires, wire],
      },
    }
  }),

  removeWire: (id) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        wires: s.editorDiagram.wires.filter((w) => w.id !== id),
      },
    }
  }),

  addInput: (ep) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        inputs: [...s.editorDiagram.inputs, ep],
      },
    }
  }),

  addOutput: (ep) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        outputs: [...s.editorDiagram.outputs, ep],
      },
    }
  }),

  removeInput: (id) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        inputs: s.editorDiagram.inputs.filter((i) => i.id !== id),
        wires: s.editorDiagram.wires.filter((w) => w.sourceBox !== id),
      },
    }
  }),

  removeOutput: (id) => set((s) => {
    if (!s.editorDiagram) return s
    return {
      editorDiagram: {
        ...s.editorDiagram,
        outputs: s.editorDiagram.outputs.filter((o) => o.id !== id),
        wires: s.editorDiagram.wires.filter((w) => w.targetBox !== id),
      },
    }
  }),

  setSelectedNode: (id) => set({ selectedNodeId: id }),

  saveDiagram: () => {
    const { editorDiagram, userDiagrams } = get()
    console.log('[SAVE] editorDiagram:', editorDiagram?.id, 'morphisms:', editorDiagram?.morphisms.length, 'wires:', editorDiagram?.wires.length)
    if (!editorDiagram) {
      console.log('[SAVE] No editorDiagram, nothing to save!')
      return
    }
    const toSave: StringDiagram = JSON.parse(JSON.stringify(editorDiagram))
    const existing = userDiagrams.findIndex((d) => d.id === toSave.id)
    console.log('[SAVE] existing index:', existing, 'userDiagrams count:', userDiagrams.length)
    const updated = existing >= 0
      ? userDiagrams.map((d) => d.id === toSave.id ? toSave : d)
      : [...userDiagrams, toSave]
    saveUserDiagrams(updated)
    console.log('[SAVE] Saved to localStorage. New userDiagrams count:', updated.length)
    // Verify localStorage
    const verify = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '[]')
    const saved = verify.find((d: StringDiagram) => d.id === toSave.id)
    console.log('[SAVE] Verified in localStorage:', saved?.id, 'morphisms:', saved?.morphisms.length)
    set({ userDiagrams: updated, editorDiagram: null, activeId: toSave.id })
  },

  loadIntoEditor: (id) => {
    const diagram = get().allDiagrams().find((d) => d.id === id)
    if (diagram) {
      // Deep clone so edits don't affect the original
      set({
        editorDiagram: JSON.parse(JSON.stringify(diagram)),
        activeId: id,
        mode: 'edit',
        selectedNodeId: null,
      })
    }
  },

  exportDiagramJSON: () => {
    const diagram = get().activeDiagram()
    return diagram ? JSON.stringify(diagram, null, 2) : null
  },

  importDiagramJSON: (json) => {
    try {
      const diagram = JSON.parse(json) as StringDiagram
      diagram.id = uniqueId('imported')
      const updated = [...get().userDiagrams, diagram]
      saveUserDiagrams(updated)
      set({ userDiagrams: updated, activeId: diagram.id })
    } catch {
      // ignore invalid JSON
    }
  },
}))
