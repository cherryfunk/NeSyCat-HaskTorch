import type { StringDiagram } from '../model/types'

// Generates D_Grammatical/BA_Interpretation/{Name}IntpData.hs and {Name}IntpTens.hs
// Pattern: D_Grammatical/BA_Interpretation/BinaryIntpData.hs / BinaryIntpTens.hs

export function generateInterpretations(diagram: StringDiagram): { path: string; content: string }[] {
  const name = pascalCase(diagram.title)
  const funcName = camelCase(diagram.title)

  return [
    generateIntpData(name, funcName, diagram),
    generateIntpTens(name, funcName, diagram),
  ]
}

function generateIntpData(name: string, funcName: string, diagram: StringDiagram): { path: string; content: string } {
  const paramInputs = diagram.inputs.filter((i) => i.side === 'top')
  const dataInputs = diagram.inputs.filter((i) => i.side !== 'top')

  const lines: string[] = []
  lines.push(`module D_Grammatical.BA_Interpretation.${name}IntpData`)
  lines.push(`  ( ${funcName}AxiomData,`)
  lines.push(`  )`)
  lines.push(`where`)
  lines.push(``)
  lines.push(`import D_Grammatical.B_Theory.${name}Formulas (${funcName})`)
  lines.push(`import A_Categorical.B_Theory.StarTheory (Universe (..))`)
  lines.push(`import A_Categorical.BA_Interpretation.StarIntp ()`)
  lines.push(``)

  // Build the axiom function
  // For MeasU: Guard = [a], ParamsLogic = (), M = Dist
  const guardParams = dataInputs.map((d) => `[Point MeasU]`)
  const otherParams = paramInputs
    .filter((p) => !p.wireType.includes('ParamsLogic'))
    .map((p) => p.wireType.replace(/ U/g, ' MeasU'))

  lines.push(`${funcName}AxiomData :: ${[...guardParams, ...otherParams, 'M MeasU (Omega MeasU)'].join(' -> ')}`)

  const guardVars = dataInputs.map((_, i) => `guard${i > 0 ? i : ''}`)
  const otherVars = paramInputs
    .filter((p) => !p.wireType.includes('ParamsLogic'))
    .map((p) => paramToVarName(p.label))

  lines.push(`${funcName}AxiomData ${[...guardVars, ...otherVars].join(' ')} =`)
  lines.push(`  ${funcName} @MeasU () ${[...guardVars, ...otherVars].join(' ')}`)
  lines.push(``)

  return {
    path: `D_Grammatical/BA_Interpretation/${name}IntpData.hs`,
    content: lines.join('\n'),
  }
}

function generateIntpTens(name: string, funcName: string, diagram: StringDiagram): { path: string; content: string } {
  const paramInputs = diagram.inputs.filter((i) => i.side === 'top')
  const dataInputs = diagram.inputs.filter((i) => i.side !== 'top')

  const lines: string[] = []
  lines.push(`module D_Grammatical.BA_Interpretation.${name}IntpTens`)
  lines.push(`  ( ${funcName}AxiomTens,`)
  lines.push(`  )`)
  lines.push(`where`)
  lines.push(``)
  lines.push(`import D_Grammatical.B_Theory.${name}Formulas (${funcName})`)
  lines.push(`import A_Categorical.B_Theory.StarTheory (Universe (..))`)
  lines.push(`import A_Categorical.BA_Interpretation.StarIntp ()`)
  lines.push(`import qualified Torch`)
  lines.push(`import Data.Functor.Identity (runIdentity)`)
  lines.push(``)

  // For GeomU: Guard = Torch.Tensor, ParamsLogic = Torch.Tensor, M = Identity
  const guardParams = dataInputs.map(() => 'Torch.Tensor')
  const lpParams = paramInputs
    .filter((p) => p.wireType.includes('ParamsLogic'))
    .map(() => 'Torch.Tensor')
  const otherParams = paramInputs
    .filter((p) => !p.wireType.includes('ParamsLogic'))
    .map((p) => p.wireType.replace(/ U/g, ' GeomU'))

  lines.push(`${funcName}AxiomTens :: ${[...lpParams, ...guardParams, ...otherParams, 'Omega GeomU'].join(' -> ')}`)

  const lpVars = paramInputs
    .filter((p) => p.wireType.includes('ParamsLogic'))
    .map(() => 'betaT')
  const guardVars = dataInputs.map((_, i) => `guard${i > 0 ? i : ''}`)
  const otherVars = paramInputs
    .filter((p) => !p.wireType.includes('ParamsLogic'))
    .map((p) => paramToVarName(p.label))

  lines.push(`${funcName}AxiomTens ${[...lpVars, ...guardVars, ...otherVars].join(' ')} =`)
  lines.push(`  runIdentity (${funcName} @GeomU ${[...lpVars, ...guardVars, ...otherVars].join(' ')})`)
  lines.push(``)

  return {
    path: `D_Grammatical/BA_Interpretation/${name}IntpTens.hs`,
    content: lines.join('\n'),
  }
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
