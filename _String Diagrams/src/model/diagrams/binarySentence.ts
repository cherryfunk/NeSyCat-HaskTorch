import type { StringDiagram } from '../types'

const haskellSource = `binarySentence lp guard paramMLP =
  bigWedge lp guard
    (binaryPredicate @frmwk lp paramMLP)`

export const binarySentenceDiagram: StringDiagram = {
  id: 'binarySentence',
  title: 'binarySentence',
  description: 'Guarded quantifier: forall x in Guard. binaryPredicate(x)',
  haskellSource,

  inputs: [
    { id: 'in-lp', label: 'ParamsLogic', wireType: 'ParamsLogic' },
    { id: 'in-guard', label: 'Guard', wireType: 'Guard' },
    { id: 'in-mlp', label: 'ParamsMLP', wireType: 'ParamsMLP' },
  ],

  outputs: [
    { id: 'out-omega', label: 'M(Omega)', wireType: 'M(Omega)' },
  ],

  morphisms: [
    {
      id: 'binaryPredicate',
      label: 'binaryPredicate',
      haskellSig: 'ParamsLogic -> ParamsMLP -> Point -> M(Omega)',
      category: 'kleisli',
      inputs: [
        { id: 'bp-in-lp', label: 'ParamsLogic', position: 'left' },
        { id: 'bp-in-mlp', label: 'ParamsMLP', position: 'left' },
      ],
      outputs: [{ id: 'bp-out', label: 'Point -> M(Omega)', position: 'right' }],
    },
    {
      id: 'bigWedge',
      label: 'bigWedge',
      haskellSig: 'ParamsLogic -> Guard -> (a -> M Omega) -> M Omega',
      category: 'logic',
      inputs: [
        { id: 'bw-in-lp', label: 'ParamsLogic', position: 'left' },
        { id: 'bw-in-guard', label: 'Guard', position: 'left' },
        { id: 'bw-in-pred', label: 'Point -> M(Omega)', position: 'left' },
      ],
      outputs: [{ id: 'bw-out', label: 'M(Omega)', position: 'right' }],
    },
  ],

  copies: [
    {
      id: 'copy-lp',
      wireType: 'ParamsLogic',
      input: { id: 'copy-lp-in', label: 'ParamsLogic', position: 'left' },
      outputs: [
        { id: 'copy-lp-out-1', label: 'ParamsLogic', position: 'right' },
        { id: 'copy-lp-out-2', label: 'ParamsLogic', position: 'right' },
      ],
    },
  ],

  wires: [
    // ParamsLogic -> copy
    { id: 'w-lp-copy', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'copy-lp', targetPort: 'copy-lp-in', wireType: 'ParamsLogic', isMonadic: false },

    // copy-lp -> binaryPredicate, bigWedge
    { id: 'w-lp-bp', sourceBox: 'copy-lp', sourcePort: 'copy-lp-out-1', targetBox: 'binaryPredicate', targetPort: 'bp-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-bw', sourceBox: 'copy-lp', sourcePort: 'copy-lp-out-2', targetBox: 'bigWedge', targetPort: 'bw-in-lp', wireType: 'ParamsLogic', isMonadic: false },

    // ParamsMLP -> binaryPredicate
    { id: 'w-mlp-bp', sourceBox: 'in-mlp', sourcePort: 'in-mlp', targetBox: 'binaryPredicate', targetPort: 'bp-in-mlp', wireType: 'ParamsMLP', isMonadic: false },

    // Guard -> bigWedge
    { id: 'w-guard-bw', sourceBox: 'in-guard', sourcePort: 'in-guard', targetBox: 'bigWedge', targetPort: 'bw-in-guard', wireType: 'Guard', isMonadic: false },

    // binaryPredicate -> bigWedge
    { id: 'w-bp-bw', sourceBox: 'binaryPredicate', sourcePort: 'bp-out', targetBox: 'bigWedge', targetPort: 'bw-in-pred', wireType: 'Point -> M(Omega)', isMonadic: false },

    // bigWedge -> output
    { id: 'w-bw-out', sourceBox: 'bigWedge', sourcePort: 'bw-out', targetBox: 'out-omega', targetPort: 'out-omega', wireType: 'M(Omega)', isMonadic: true },
  ],
}
