import type { StringDiagram, MorphismDef } from '../model/types'

// Generates C_Domain/B_Theory/{Name}Theory.hs
// Pattern: C_Domain/B_Theory/BinaryTheory.hs

export function generateTheory(diagram: StringDiagram): { path: string; content: string } | null {
  const domainMorphs = diagram.morphisms.filter((m) => m.layer === 'domain')
  if (domainMorphs.length === 0) return null

  const name = pascalCase(diagram.title)
  const tarskiMorphs = domainMorphs.filter((m) => m.mode === 'tarski')
  const kleisliMorphs = domainMorphs.filter((m) => m.mode === 'kleisli')

  // Collect unique sorts from port wire types (excluding Omega, ParamsLogic, etc.)
  const logicalTypes = new Set(['Omega', 'Omega U', 'M(Omega)', 'M(Omega U)', 'ParamsLogic', 'ParamsMLP', 'tau'])
  const sorts = new Set<string>()
  for (const m of domainMorphs) {
    for (const p of [...m.inputs, ...m.outputs]) {
      if (!logicalTypes.has(p.label)) {
        sorts.add(p.label)
      }
    }
  }

  const lines: string[] = []

  // Module header
  lines.push(`{-# LANGUAGE TypeFamilies #-}`)
  lines.push(`{-# LANGUAGE MultiParamTypeClasses #-}`)
  lines.push(``)
  lines.push(`module C_Domain.B_Theory.${name}Theory`)
  lines.push(`  ( ${name}Sorts (..),`)
  if (tarskiMorphs.length > 0) lines.push(`    ${name}Fun (..),`)
  if (kleisliMorphs.length > 0) lines.push(`    ${name}KlFun (..),`)
  // Remove trailing comma from last export
  const lastIdx = lines.length - 1
  lines[lastIdx] = lines[lastIdx].replace(/,$/, '')
  lines.push(`  )`)
  lines.push(`where`)
  lines.push(``)
  lines.push(`import A_Categorical.B_Theory.StarTheory (Universe (..))`)
  lines.push(``)

  // Sorts class
  lines.push(`class ${name}Sorts u where`)
  for (const sort of sorts) {
    const sortName = sort.replace(/ U$/, '')
    lines.push(`  type ${sortName} u :: Type`)
  }
  lines.push(``)

  // Tarski function class
  if (tarskiMorphs.length > 0) {
    lines.push(`class ${name}Fun u where`)
    for (const m of tarskiMorphs) {
      lines.push(`  ${m.label} :: ${buildSigFromPorts(m)}`)
    }
    lines.push(``)
  }

  // Kleisli function class
  if (kleisliMorphs.length > 0) {
    lines.push(`class ${name}KlFun u where`)
    for (const m of kleisliMorphs) {
      lines.push(`  ${m.label} :: ${buildKleisliSigFromPorts(m)}`)
    }
    lines.push(``)
  }

  return {
    path: `C_Domain/B_Theory/${name}Theory.hs`,
    content: lines.join('\n'),
  }
}

function buildSigFromPorts(m: MorphismDef): string {
  const parts: string[] = []
  for (const p of (m.paramInputs ?? [])) parts.push(p.label)
  for (const p of m.inputs) parts.push(p.label)
  for (const p of m.outputs) parts.push(p.label)
  return parts.join(' -> ')
}

function buildKleisliSigFromPorts(m: MorphismDef): string {
  const parts: string[] = []
  for (const p of (m.paramInputs ?? [])) parts.push(p.label)
  for (const p of m.inputs) parts.push(p.label)
  const outType = m.outputs[0]?.label ?? 'Omega U'
  parts.push(`M U (${outType})`)
  return parts.join(' -> ')
}

function pascalCase(s: string): string {
  return s
    .replace(/[^a-zA-Z0-9]/g, ' ')
    .split(' ')
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join('')
}
