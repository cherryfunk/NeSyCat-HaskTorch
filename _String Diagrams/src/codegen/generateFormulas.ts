import type { StringDiagram, MorphismDef } from '../model/types'

// Generates D_Grammatical/B_Theory/{Name}Formulas.hs
// Pattern: D_Grammatical/B_Theory/BinaryFormulas.hs

export function generateFormulas(diagram: StringDiagram): { path: string; content: string } {
  const name = pascalCase(diagram.title)
  const funcName = camelCase(diagram.title)

  // Topologically sort morphisms by wire dependencies
  const sorted = topoSort(diagram)

  // Collect all type class constraints
  const constraints = new Set<string>()
  for (const m of diagram.morphisms) {
    if (m.haskellClass) {
      for (const c of m.haskellClass.split(',').map((s) => s.trim())) {
        if (c) constraints.add(c)
      }
    }
  }
  // Always add Monad if any Kleisli morphism exists
  if (diagram.morphisms.some((m) => m.mode === 'kleisli')) {
    constraints.add('Monad (M U)')
  }

  // Determine if we need do-notation (any Kleisli morphism)
  const needsDo = diagram.morphisms.some((m) => m.mode === 'kleisli')

  // Build the function parameters from diagram inputs
  const paramInputs = diagram.inputs.filter((i) => i.side === 'top')
  const dataInputs = diagram.inputs.filter((i) => i.side !== 'top')

  const paramNames: Record<string, string> = {}
  for (const p of paramInputs) {
    paramNames[p.id] = paramToVarName(p.label)
  }
  const dataParamNames: Record<string, string> = {}
  for (const d of dataInputs) {
    dataParamNames[d.id] = paramToVarName(d.label)
  }

  // Build variable names for morphism outputs
  const varNames: Record<string, string> = {}
  for (const m of sorted) {
    varNames[m.id] = m.label.replace(/[^a-zA-Z0-9]/g, '') + 'Result'
  }

  const lines: string[] = []

  // Module header
  lines.push(`{-# LANGUAGE AllowAmbiguousTypes #-}`)
  lines.push(`{-# LANGUAGE FlexibleContexts #-}`)
  lines.push(`{-# LANGUAGE MultiParamTypeClasses #-}`)
  lines.push(`{-# LANGUAGE ScopedTypeVariables #-}`)
  lines.push(`{-# LANGUAGE TypeApplications #-}`)
  lines.push(`{-# LANGUAGE TypeFamilies #-}`)
  lines.push(`{-# LANGUAGE TypeOperators #-}`)
  lines.push(``)
  lines.push(`module D_Grammatical.B_Theory.${name}Formulas`)
  lines.push(`  ( ${funcName},`)
  lines.push(`  )`)
  lines.push(`where`)
  lines.push(``)

  // Imports
  lines.push(`import A_Categorical.B_Theory.StarTheory (Universe (..))`)
  if (diagram.morphisms.some((m) => m.haskellClass.includes('A2MonBLatTheory'))) {
    lines.push(`import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..), Guard)`)
  }
  if (diagram.morphisms.some((m) => m.haskellClass.includes('TwoMonBLatTheory'))) {
    lines.push(`import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))`)
  }
  // Domain theory import
  const domainMorphs = diagram.morphisms.filter((m) => m.layer === 'domain')
  if (domainMorphs.length > 0) {
    const tarskiMorphs = domainMorphs.filter((m) => m.mode === 'tarski')
    const kleisliMorphs = domainMorphs.filter((m) => m.mode === 'kleisli')
    const imports: string[] = []
    if (tarskiMorphs.length > 0) imports.push(`${name}Fun (..)`)
    if (kleisliMorphs.length > 0) imports.push(`${name}KlFun (..)`)
    lines.push(`import C_Domain.B_Theory.${name}Theory (${imports.join(', ')})`)
  }
  lines.push(``)

  // Type signature
  const constraintList = Array.from(constraints).join(',\n    ')
  const allParams = [
    ...paramInputs.map((p) => p.wireType),
    ...dataInputs.map((p) => p.wireType),
  ]
  const returnType = needsDo ? 'M U (Omega U)' : 'Omega U'
  const sigParts = [...allParams, returnType].join(' ->\n  ')

  lines.push(`${funcName} ::`)
  lines.push(`  forall u.`)
  lines.push(`  ( ${constraintList}`)
  lines.push(`  ) =>`)
  lines.push(`  ${sigParts}`)

  // Function body
  const allParamVars = [
    ...paramInputs.map((p) => paramNames[p.id]),
    ...dataInputs.map((p) => dataParamNames[p.id]),
  ]
  lines.push(`${funcName} ${allParamVars.join(' ')} =${needsDo ? ' do' : ''}`)

  // Generate bindings in topological order
  for (const m of sorted) {
    const args = resolveArgs(m, diagram, paramNames, dataParamNames, varNames)
    const call = `${m.label}${args.length > 0 ? ' ' + args.join(' ') : ''}`

    if (m.mode === 'kleisli' && needsDo) {
      lines.push(`  ${varNames[m.id]} <- ${call}`)
    } else if (m === sorted[sorted.length - 1]) {
      // Last morphism is the return value
      if (needsDo) {
        lines.push(`  return (${call})`)
      } else {
        lines.push(`  ${call}`)
      }
    } else {
      lines.push(`  let ${varNames[m.id]} = ${call}`)
    }
  }

  lines.push(``)

  return {
    path: `D_Grammatical/B_Theory/${name}Formulas.hs`,
    content: lines.join('\n'),
  }
}

function resolveArgs(
  morph: MorphismDef,
  diagram: StringDiagram,
  paramNames: Record<string, string>,
  dataParamNames: Record<string, string>,
  varNames: Record<string, string>,
): string[] {
  const args: string[] = []

  // Param inputs (from top)
  for (const p of (morph.paramInputs ?? [])) {
    const wire = diagram.wires.find((w) => w.targetBox === morph.id && w.targetPort === p.id)
    if (wire) {
      args.push(paramNames[wire.sourceBox] ?? varNames[wire.sourceBox] ?? wire.sourceBox)
    }
  }

  // Data inputs (from left)
  for (const p of morph.inputs) {
    const wire = diagram.wires.find((w) => w.targetBox === morph.id && w.targetPort === p.id)
    if (wire) {
      args.push(dataParamNames[wire.sourceBox] ?? varNames[wire.sourceBox] ?? wire.sourceBox)
    }
  }

  return args
}

function topoSort(diagram: StringDiagram): MorphismDef[] {
  const morphMap = new Map(diagram.morphisms.map((m) => [m.id, m]))
  const inDegree = new Map<string, number>()
  const adj = new Map<string, string[]>()

  for (const m of diagram.morphisms) {
    inDegree.set(m.id, 0)
    adj.set(m.id, [])
  }

  for (const w of diagram.wires) {
    if (morphMap.has(w.sourceBox) && morphMap.has(w.targetBox)) {
      adj.get(w.sourceBox)!.push(w.targetBox)
      inDegree.set(w.targetBox, (inDegree.get(w.targetBox) ?? 0) + 1)
    }
  }

  const queue: string[] = []
  for (const [id, deg] of inDegree) {
    if (deg === 0) queue.push(id)
  }

  const result: MorphismDef[] = []
  while (queue.length > 0) {
    const id = queue.shift()!
    const morph = morphMap.get(id)
    if (morph) result.push(morph)
    for (const next of (adj.get(id) ?? [])) {
      const newDeg = (inDegree.get(next) ?? 1) - 1
      inDegree.set(next, newDeg)
      if (newDeg === 0) queue.push(next)
    }
  }

  return result
}

function paramToVarName(label: string): string {
  const l = label.replace(/[^a-zA-Z0-9]/g, '')
  return l[0].toLowerCase() + l.slice(1)
}

function pascalCase(s: string): string {
  return s.replace(/[^a-zA-Z0-9]/g, ' ').split(' ').filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1)).join('')
}

function camelCase(s: string): string {
  const p = pascalCase(s)
  return p[0].toLowerCase() + p.slice(1)
}
