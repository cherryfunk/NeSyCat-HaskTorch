import type { StringDiagram } from '../types'

const haskellSource = `binarySentence lp guard paramMLP =
  bigWedge lp guard
    (binaryPredicate @U lp paramMLP)`

export const binarySentenceDiagram: StringDiagram = {
  id: 'binarySentence',
  title: 'binarySentence',
  description: 'Guarded quantifier: forall x in Guard. binaryPredicate(x)',
  haskellSource,

  inputs: [
    { id: 'in-lp', label: 'ParamsLogic', wireType: 'ParamsLogic', side: 'top' },
    { id: 'in-guard', label: 'Guard', wireType: 'Guard', side: 'left' },
    { id: 'in-mlp', label: 'ParamsMLP', wireType: 'ParamsMLP', side: 'top' },
  ],

  outputs: [
    { id: 'out-omega', label: 'M(Omega)', wireType: 'M(Omega)' },
  ],

  morphisms: [
    {
      id: 'binaryPredicate',
      label: 'binaryPredicate',
      haskellSig: 'binaryPredicate :: ParamsLogic (Omega U) -> ParamsMLP -> Point U -> M U (Omega U)',
      haskellClass: 'BinaryKlFun U, TwoMonBLatTheory U (Omega U)',
      instances: [
        {
          universe: 'any U',
          def: `binaryPredicate lp paramMLP pt = do
  pred <- classifierA @U paramMLP pt
  let label = labelA @U pt
  return (wedge lp
    (implies lp label pred)
    (implies lp (neg label) (neg pred)))`,
        },
      ],
      mode: 'kleisli',
      inputs: [],
      outputs: [{ id: 'bp-out', label: 'Point -> M(Omega)', position: 'right' }],
      paramInputs: [
        { id: 'bp-in-lp', label: 'ParamsLogic', position: 'top' },
        { id: 'bp-in-mlp', label: 'ParamsMLP', position: 'top' },
      ],
    },
    {
      id: 'bigWedge',
      label: 'bigWedge',
      haskellSig: 'bigWedge :: ParamsLogic tau -> Guard U a -> (a -> M U tau) -> M U tau',
      haskellClass: 'A2MonBLatTheory a U tau',
      instances: [
        {
          universe: 'Bool (MeasU)',
          def: `bigWedge _ guard phi = do
  omegas <- mapM phi guard
  return (foldl (wedge ()) True omegas)`,
        },
        {
          universe: 'Tensor (GeomU)',
          def: `bigWedge betaT guard phi =
  let result = runIdentity (phi (UnsafeMkTensor guard))
      n = head (shape guard)
      negResult = neg result
      lse = logsumexp (toDynamic negResult * betaT) 0 False
      reduced = negate ((lse - log n) / betaT)
   in Identity (UnsafeMkTensor (reshape [1] reduced))`,
        },
      ],
      mode: 'tarski',
      inputs: [
        { id: 'bw-in-guard', label: 'Guard', position: 'left' },
        { id: 'bw-in-pred', label: 'Point -> M(Omega)', position: 'left' },
      ],
      outputs: [{ id: 'bw-out', label: 'M(Omega)', position: 'right' }],
      paramInputs: [
        { id: 'bw-in-lp', label: 'ParamsLogic', position: 'top' },
      ],
    },
  ],

  copies: [],

  wires: [
    { id: 'w-lp-bp', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'binaryPredicate', targetPort: 'bp-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-bw', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'bigWedge', targetPort: 'bw-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-mlp-bp', sourceBox: 'in-mlp', sourcePort: 'in-mlp', targetBox: 'binaryPredicate', targetPort: 'bp-in-mlp', wireType: 'ParamsMLP', isMonadic: false },
    { id: 'w-guard-bw', sourceBox: 'in-guard', sourcePort: 'in-guard', targetBox: 'bigWedge', targetPort: 'bw-in-guard', wireType: 'Guard', isMonadic: false },
    { id: 'w-bp-bw', sourceBox: 'binaryPredicate', sourcePort: 'bp-out', targetBox: 'bigWedge', targetPort: 'bw-in-pred', wireType: 'Point -> M(Omega)', isMonadic: false },
    { id: 'w-bw-out', sourceBox: 'bigWedge', sourcePort: 'bw-out', targetBox: 'out-omega', targetPort: 'out-omega', wireType: 'M(Omega)', isMonadic: false },
  ],
}
