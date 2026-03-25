import type { StringDiagram } from '../types'

const haskellSource = `binaryPredicate lp paramMLP pt = do
  pred <- classifierA @U paramMLP pt
  let label = labelA @U pt
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
    { id: 'in-pt', label: 'Point', wireType: 'Point', side: 'left' },
    { id: 'in-mlp', label: 'ParamsMLP', wireType: 'ParamsMLP', side: 'top' },
    { id: 'in-lp', label: 'ParamsLogic', wireType: 'ParamsLogic', side: 'top' },
  ],

  outputs: [
    { id: 'out-omega', label: 'M(Omega)', wireType: 'M(Omega)' },
  ],

  morphisms: [
    {
      id: 'labelA',
      label: 'labelA',
      haskellSig: 'labelA :: Point U -> Omega U',
      haskellClass: 'BinaryFun U',
      instances: [
        {
          universe: 'MeasU',
          def: `labelA (x1, x2) =
  let dx = x1 - 0.5
      dy = x2 - 0.5
   in dx * dx + dy * dy < 0.09`,
        },
        {
          universe: 'GeomU',
          def: `labelA ptTensor =
  let pt = toDynamic ptTensor
      center = mulScalar (onesLike pt) 0.5
      diff = pt \`sub\` center
      dist2 = sumDim (Dim (-1)) KeepDim Float (diff * diff)
      radiusSq = mulScalar (onesLike dist2) 0.09
      isInside = lt dist2 radiusSq
      val = toType Float isInside * 20.0 - 10.0
   in UnsafeMkTensor val`,
        },
      ],
      mode: 'tarski',
      layer: 'domain',
      inputs: [{ id: 'labelA-in-pt', label: 'Point', position: 'left' }],
      outputs: [{ id: 'labelA-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'classifierA',
      label: 'classifierA',
      haskellSig: 'classifierA :: ParamsMLP -> Point U -> M U (Omega U)',
      haskellClass: 'BinaryKlFun U',
      instances: [
        {
          universe: 'MeasU',
          def: `classifierA paramMLP pt =
  let ptTens = encPoint @MeasU @GeomU pt
      logits = UnsafeMkTensor
        (hThetaReal paramMLP (reshape [1,2] (toDynamic ptTens)))
   in decOmega @MeasU @GeomU logits`,
        },
        {
          universe: 'GeomU',
          def: `classifierA paramMLP ptTensor =
  Identity (UnsafeMkTensor (hThetaReal paramMLP (toDynamic ptTensor)))`,
        },
      ],
      mode: 'kleisli',
      layer: 'domain',
      inputs: [
        { id: 'classA-in-pt', label: 'Point', position: 'left' },
      ],
      outputs: [{ id: 'classA-out', label: 'Omega', position: 'right' }],
      paramInputs: [
        { id: 'classA-in-mlp', label: 'ParamsMLP', position: 'top' },
      ],
    },
    {
      id: 'neg-label',
      label: 'neg',
      haskellSig: 'neg :: tau -> tau',
      haskellClass: 'TwoMonBLatTheory U tau',
      instances: [
        { universe: 'Bool', def: 'neg = not' },
        { universe: 'Tensor', def: 'neg a = UnsafeMkTensor (negate (toDynamic a))' },
      ],
      mode: 'tarski',
      layer: 'logical',
      inputs: [{ id: 'neg-label-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'neg-label-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'neg-pred',
      label: 'neg',
      haskellSig: 'neg :: tau -> tau',
      haskellClass: 'TwoMonBLatTheory U tau',
      instances: [
        { universe: 'Bool', def: 'neg = not' },
        { universe: 'Tensor', def: 'neg a = UnsafeMkTensor (negate (toDynamic a))' },
      ],
      mode: 'tarski',
      layer: 'logical',
      inputs: [{ id: 'neg-pred-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'neg-pred-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'implies-1',
      label: 'implies',
      haskellSig: 'implies :: ParamsLogic tau -> tau -> tau -> tau',
      haskellClass: 'TwoMonBLatTheory U tau',
      instances: [
        { universe: 'default', def: 'implies lp a b = vee lp (neg a) b' },
        { universe: 'Bool', def: 'implies _ a b = not a || b' },
      ],
      mode: 'tarski',
      layer: 'logical',
      inputs: [
        { id: 'imp1-in-a', label: 'Omega', position: 'left' },
        { id: 'imp1-in-b', label: 'Omega', position: 'left' },
      ],
      outputs: [{ id: 'imp1-out', label: 'Omega', position: 'right' }],
      paramInputs: [
        { id: 'imp1-in-lp', label: 'ParamsLogic', position: 'top' },
      ],
    },
    {
      id: 'implies-2',
      label: 'implies',
      haskellSig: 'implies :: ParamsLogic tau -> tau -> tau -> tau',
      haskellClass: 'TwoMonBLatTheory U tau',
      instances: [
        { universe: 'default', def: 'implies lp a b = vee lp (neg a) b' },
        { universe: 'Bool', def: 'implies _ a b = not a || b' },
      ],
      mode: 'tarski',
      layer: 'logical',
      inputs: [
        { id: 'imp2-in-a', label: 'Omega', position: 'left' },
        { id: 'imp2-in-b', label: 'Omega', position: 'left' },
      ],
      outputs: [{ id: 'imp2-out', label: 'Omega', position: 'right' }],
      paramInputs: [
        { id: 'imp2-in-lp', label: 'ParamsLogic', position: 'top' },
      ],
    },
    {
      id: 'wedge',
      label: 'wedge',
      haskellSig: 'wedge :: ParamsLogic tau -> tau -> tau -> tau',
      haskellClass: 'TwoMonBLatTheory U tau',
      instances: [
        { universe: 'default', def: 'wedge lp a b = neg (vee lp (neg a) (neg b))' },
        { universe: 'Bool', def: 'wedge _ = (&&)' },
      ],
      mode: 'tarski',
      layer: 'logical',
      inputs: [
        { id: 'wedge-in-a', label: 'Omega', position: 'left' },
        { id: 'wedge-in-b', label: 'Omega', position: 'left' },
      ],
      outputs: [{ id: 'wedge-out', label: 'Omega', position: 'right' }],
      paramInputs: [
        { id: 'wedge-in-lp', label: 'ParamsLogic', position: 'top' },
      ],
    },
    {
      id: 'return',
      label: 'return',
      haskellSig: 'return :: Monad m => a -> m a',
      haskellClass: 'Monad m',
      instances: [
        { universe: 'Identity', def: 'return = Identity' },
        { universe: 'Dist', def: 'return = certainly' },
      ],
      mode: 'kleisli',
      layer: 'logical',
      inputs: [{ id: 'return-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'return-out', label: 'M(Omega)', position: 'right' }],
    },
  ],

  copies: [],

  wires: [
    { id: 'w-pt-labelA', sourceBox: 'in-pt', sourcePort: 'in-pt', targetBox: 'labelA', targetPort: 'labelA-in-pt', wireType: 'Point', isMonadic: false },
    { id: 'w-pt-classA', sourceBox: 'in-pt', sourcePort: 'in-pt', targetBox: 'classifierA', targetPort: 'classA-in-pt', wireType: 'Point', isMonadic: false },
    { id: 'w-mlp-classA', sourceBox: 'in-mlp', sourcePort: 'in-mlp', targetBox: 'classifierA', targetPort: 'classA-in-mlp', wireType: 'ParamsMLP', isMonadic: false },
    { id: 'w-lp-imp1', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'implies-1', targetPort: 'imp1-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-imp2', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'implies-2', targetPort: 'imp2-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-wedge', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'wedge', targetPort: 'wedge-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-label-imp1', sourceBox: 'labelA', sourcePort: 'labelA-out', targetBox: 'implies-1', targetPort: 'imp1-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-label-neg', sourceBox: 'labelA', sourcePort: 'labelA-out', targetBox: 'neg-label', targetPort: 'neg-label-in', wireType: 'Omega', isMonadic: false },
    { id: 'w-pred-imp1', sourceBox: 'classifierA', sourcePort: 'classA-out', targetBox: 'implies-1', targetPort: 'imp1-in-b', wireType: 'Omega', isMonadic: false },
    { id: 'w-pred-neg', sourceBox: 'classifierA', sourcePort: 'classA-out', targetBox: 'neg-pred', targetPort: 'neg-pred-in', wireType: 'Omega', isMonadic: false },
    { id: 'w-neg-label-imp2', sourceBox: 'neg-label', sourcePort: 'neg-label-out', targetBox: 'implies-2', targetPort: 'imp2-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-neg-pred-imp2', sourceBox: 'neg-pred', sourcePort: 'neg-pred-out', targetBox: 'implies-2', targetPort: 'imp2-in-b', wireType: 'Omega', isMonadic: false },
    { id: 'w-imp1-wedge', sourceBox: 'implies-1', sourcePort: 'imp1-out', targetBox: 'wedge', targetPort: 'wedge-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-imp2-wedge', sourceBox: 'implies-2', sourcePort: 'imp2-out', targetBox: 'wedge', targetPort: 'wedge-in-b', wireType: 'Omega', isMonadic: false },
    { id: 'w-wedge-return', sourceBox: 'wedge', sourcePort: 'wedge-out', targetBox: 'return', targetPort: 'return-in', wireType: 'Omega', isMonadic: false },
    { id: 'w-return-out', sourceBox: 'return', sourcePort: 'return-out', targetBox: 'out-omega', targetPort: 'out-omega', wireType: 'M(Omega)', isMonadic: false },
  ],
}
