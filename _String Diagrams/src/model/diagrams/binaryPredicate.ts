import type { StringDiagram } from '../types'

const haskellSource = `binaryPredicate lp paramMLP pt = do
  pred <- classifierA @frmwk paramMLP pt
  let label = labelA @frmwk pt
  return (wedge lp
    (implies lp label pred)
    (implies lp (neg label) (neg pred))
  )`

export const binaryPredicateDiagram: StringDiagram = {
  id: 'binaryPredicate',
  title: 'binaryPredicate',
  description: 'Pointwise binary classification predicate: (label -> pred) /\\ (neg label -> neg pred)',
  haskellSource,

  inputs: [
    { id: 'in-pt', label: 'Point', wireType: 'Point' },
    { id: 'in-mlp', label: 'ParamsMLP', wireType: 'ParamsMLP' },
    { id: 'in-lp', label: 'ParamsLogic', wireType: 'ParamsLogic' },
  ],

  outputs: [
    { id: 'out-omega', label: 'M(Omega)', wireType: 'M(Omega)' },
  ],

  morphisms: [
    {
      id: 'labelA',
      label: 'labelA',
      haskellSig: 'Point -> Omega',
      category: 'pure',
      inputs: [{ id: 'labelA-in-pt', label: 'Point', position: 'left' }],
      outputs: [{ id: 'labelA-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'classifierA',
      label: 'classifierA',
      haskellSig: 'ParamsMLP -> Point -> M(Omega)',
      category: 'kleisli',
      inputs: [
        { id: 'classA-in-mlp', label: 'ParamsMLP', position: 'left' },
        { id: 'classA-in-pt', label: 'Point', position: 'left' },
      ],
      outputs: [{ id: 'classA-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'neg-label',
      label: 'neg',
      haskellSig: 'Omega -> Omega',
      category: 'logic',
      inputs: [{ id: 'neg-label-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'neg-label-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'neg-pred',
      label: 'neg',
      haskellSig: 'Omega -> Omega',
      category: 'logic',
      inputs: [{ id: 'neg-pred-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'neg-pred-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'implies-1',
      label: 'implies',
      haskellSig: 'ParamsLogic -> Omega -> Omega -> Omega',
      category: 'logic',
      inputs: [
        { id: 'imp1-in-lp', label: 'ParamsLogic', position: 'left' },
        { id: 'imp1-in-a', label: 'Omega', position: 'left' },
        { id: 'imp1-in-b', label: 'Omega', position: 'left' },
      ],
      outputs: [{ id: 'imp1-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'implies-2',
      label: 'implies',
      haskellSig: 'ParamsLogic -> Omega -> Omega -> Omega',
      category: 'logic',
      inputs: [
        { id: 'imp2-in-lp', label: 'ParamsLogic', position: 'left' },
        { id: 'imp2-in-a', label: 'Omega', position: 'left' },
        { id: 'imp2-in-b', label: 'Omega', position: 'left' },
      ],
      outputs: [{ id: 'imp2-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'wedge',
      label: 'wedge',
      haskellSig: 'ParamsLogic -> Omega -> Omega -> Omega',
      category: 'logic',
      inputs: [
        { id: 'wedge-in-lp', label: 'ParamsLogic', position: 'left' },
        { id: 'wedge-in-a', label: 'Omega', position: 'left' },
        { id: 'wedge-in-b', label: 'Omega', position: 'left' },
      ],
      outputs: [{ id: 'wedge-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'return',
      label: 'return',
      haskellSig: 'Omega -> M(Omega)',
      category: 'kleisli',
      inputs: [{ id: 'return-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'return-out', label: 'M(Omega)', position: 'right' }],
    },
  ],

  copies: [
    {
      id: 'copy-pt',
      wireType: 'Point',
      input: { id: 'copy-pt-in', label: 'Point', position: 'left' },
      outputs: [
        { id: 'copy-pt-out-1', label: 'Point', position: 'right' },
        { id: 'copy-pt-out-2', label: 'Point', position: 'right' },
      ],
    },
    {
      id: 'copy-label',
      wireType: 'Omega',
      input: { id: 'copy-label-in', label: 'Omega', position: 'left' },
      outputs: [
        { id: 'copy-label-out-1', label: 'Omega', position: 'right' },
        { id: 'copy-label-out-2', label: 'Omega', position: 'right' },
      ],
    },
    {
      id: 'copy-pred',
      wireType: 'Omega',
      input: { id: 'copy-pred-in', label: 'Omega', position: 'left' },
      outputs: [
        { id: 'copy-pred-out-1', label: 'Omega', position: 'right' },
        { id: 'copy-pred-out-2', label: 'Omega', position: 'right' },
      ],
    },
    {
      id: 'copy-lp',
      wireType: 'ParamsLogic',
      input: { id: 'copy-lp-in', label: 'ParamsLogic', position: 'left' },
      outputs: [
        { id: 'copy-lp-out-1', label: 'ParamsLogic', position: 'right' },
        { id: 'copy-lp-out-2', label: 'ParamsLogic', position: 'right' },
        { id: 'copy-lp-out-3', label: 'ParamsLogic', position: 'right' },
      ],
    },
  ],

  wires: [
    // Input -> copy nodes
    { id: 'w-pt-copy', sourceBox: 'in-pt', sourcePort: 'in-pt', targetBox: 'copy-pt', targetPort: 'copy-pt-in', wireType: 'Point', isMonadic: false },
    { id: 'w-lp-copy', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'copy-lp', targetPort: 'copy-lp-in', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-mlp-classA', sourceBox: 'in-mlp', sourcePort: 'in-mlp', targetBox: 'classifierA', targetPort: 'classA-in-mlp', wireType: 'ParamsMLP', isMonadic: false },

    // copy-pt -> labelA, classifierA
    { id: 'w-pt-labelA', sourceBox: 'copy-pt', sourcePort: 'copy-pt-out-1', targetBox: 'labelA', targetPort: 'labelA-in-pt', wireType: 'Point', isMonadic: false },
    { id: 'w-pt-classA', sourceBox: 'copy-pt', sourcePort: 'copy-pt-out-2', targetBox: 'classifierA', targetPort: 'classA-in-pt', wireType: 'Point', isMonadic: false },

    // labelA -> copy-label
    { id: 'w-labelA-copy', sourceBox: 'labelA', sourcePort: 'labelA-out', targetBox: 'copy-label', targetPort: 'copy-label-in', wireType: 'Omega', isMonadic: false },

    // classifierA -> copy-pred
    { id: 'w-classA-copy', sourceBox: 'classifierA', sourcePort: 'classA-out', targetBox: 'copy-pred', targetPort: 'copy-pred-in', wireType: 'Omega', isMonadic: true },

    // copy-label -> implies-1 (label), neg-label
    { id: 'w-label-imp1', sourceBox: 'copy-label', sourcePort: 'copy-label-out-1', targetBox: 'implies-1', targetPort: 'imp1-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-label-neg', sourceBox: 'copy-label', sourcePort: 'copy-label-out-2', targetBox: 'neg-label', targetPort: 'neg-label-in', wireType: 'Omega', isMonadic: false },

    // copy-pred -> implies-1 (pred), neg-pred
    { id: 'w-pred-imp1', sourceBox: 'copy-pred', sourcePort: 'copy-pred-out-1', targetBox: 'implies-1', targetPort: 'imp1-in-b', wireType: 'Omega', isMonadic: false },
    { id: 'w-pred-neg', sourceBox: 'copy-pred', sourcePort: 'copy-pred-out-2', targetBox: 'neg-pred', targetPort: 'neg-pred-in', wireType: 'Omega', isMonadic: false },

    // neg -> implies-2
    { id: 'w-neg-label-imp2', sourceBox: 'neg-label', sourcePort: 'neg-label-out', targetBox: 'implies-2', targetPort: 'imp2-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-neg-pred-imp2', sourceBox: 'neg-pred', sourcePort: 'neg-pred-out', targetBox: 'implies-2', targetPort: 'imp2-in-b', wireType: 'Omega', isMonadic: false },

    // copy-lp -> implies-1, implies-2, wedge
    { id: 'w-lp-imp1', sourceBox: 'copy-lp', sourcePort: 'copy-lp-out-1', targetBox: 'implies-1', targetPort: 'imp1-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-imp2', sourceBox: 'copy-lp', sourcePort: 'copy-lp-out-2', targetBox: 'implies-2', targetPort: 'imp2-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-wedge', sourceBox: 'copy-lp', sourcePort: 'copy-lp-out-3', targetBox: 'wedge', targetPort: 'wedge-in-lp', wireType: 'ParamsLogic', isMonadic: false },

    // implies -> wedge
    { id: 'w-imp1-wedge', sourceBox: 'implies-1', sourcePort: 'imp1-out', targetBox: 'wedge', targetPort: 'wedge-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-imp2-wedge', sourceBox: 'implies-2', sourcePort: 'imp2-out', targetBox: 'wedge', targetPort: 'wedge-in-b', wireType: 'Omega', isMonadic: false },

    // wedge -> return
    { id: 'w-wedge-return', sourceBox: 'wedge', sourcePort: 'wedge-out', targetBox: 'return', targetPort: 'return-in', wireType: 'Omega', isMonadic: false },

    // return -> output
    { id: 'w-return-out', sourceBox: 'return', sourcePort: 'return-out', targetBox: 'out-omega', targetPort: 'out-omega', wireType: 'M(Omega)', isMonadic: true },
  ],
}
