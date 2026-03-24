export interface PortDef {
  id: string
  label: string
  position: 'left' | 'right'
}

export type MorphismCategory = 'pure' | 'kleisli' | 'logic'

export interface MorphismDef {
  id: string
  label: string
  haskellSig: string
  category: MorphismCategory
  inputs: PortDef[]
  outputs: PortDef[]
}

export interface CopyDef {
  id: string
  wireType: string
  input: PortDef
  outputs: PortDef[]
}

export interface WireDef {
  id: string
  sourceBox: string
  sourcePort: string
  targetBox: string
  targetPort: string
  wireType: string
  isMonadic: boolean
}

export interface DiagramEndpoint {
  id: string
  label: string
  wireType: string
}

export interface StringDiagram {
  id: string
  title: string
  description: string
  haskellSource: string
  morphisms: MorphismDef[]
  copies: CopyDef[]
  wires: WireDef[]
  inputs: DiagramEndpoint[]
  outputs: DiagramEndpoint[]
}
