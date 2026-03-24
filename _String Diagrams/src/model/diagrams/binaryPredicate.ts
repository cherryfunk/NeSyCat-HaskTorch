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
      haskellSig: 'labelA :: Point frmwk -> Omega frmwk',
      haskellDef: `-- class BinaryFun frmwk
labelA :: Point frmwk -> Omega frmwk

-- MeasU instance:
labelA (x1, x2) =
  let dx = x1 - 0.5
      dy = x2 - 0.5
   in dx * dx + dy * dy < 0.09`,
      mode: 'tarski',
      inputs: [{ id: 'labelA-in-pt', label: 'Point', position: 'left' }],
      outputs: [{ id: 'labelA-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'classifierA',
      label: 'classifierA',
      haskellSig: 'classifierA :: ParamsMLP -> Point frmwk -> M frmwk (Omega frmwk)',
      haskellDef: `-- class BinaryKlFun frmwk
classifierA :: ParamsMLP -> Point frmwk -> M frmwk (Omega frmwk)

-- GeomU instance:
classifierA paramMLP ptTensor =
  Identity (UnsafeMkTensor (hThetaReal paramMLP (toDynamic ptTensor)))`,
      mode: 'kleisli',
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
      haskellDef: `-- class TwoMonBLatTheory frmwk tau
neg :: tau -> tau

-- Bool instance:
neg = not

-- Tensor instance:
neg a = UnsafeMkTensor (negate (toDynamic a))`,
      mode: 'tarski',
      inputs: [{ id: 'neg-label-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'neg-label-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'neg-pred',
      label: 'neg',
      haskellSig: 'neg :: tau -> tau',
      haskellDef: `-- class TwoMonBLatTheory frmwk tau
neg :: tau -> tau

-- Bool instance:
neg = not

-- Tensor instance:
neg a = UnsafeMkTensor (negate (toDynamic a))`,
      mode: 'tarski',
      inputs: [{ id: 'neg-pred-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'neg-pred-out', label: 'Omega', position: 'right' }],
    },
    {
      id: 'implies-1',
      label: 'implies',
      haskellSig: 'implies :: ParamsLogic tau -> tau -> tau -> tau',
      haskellDef: `-- class TwoMonBLatTheory frmwk tau
implies :: ParamsLogic tau -> tau -> tau -> tau

-- default:
implies lp a b = vee lp (neg a) b

-- Bool instance:
implies _ a b = not a || b`,
      mode: 'tarski',
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
      haskellDef: `-- class TwoMonBLatTheory frmwk tau
implies :: ParamsLogic tau -> tau -> tau -> tau

-- default:
implies lp a b = vee lp (neg a) b

-- Bool instance:
implies _ a b = not a || b`,
      mode: 'tarski',
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
      haskellDef: `-- class TwoMonBLatTheory frmwk tau
wedge :: ParamsLogic tau -> tau -> tau -> tau

-- default (De Morgan):
wedge lp a b = neg (vee lp (neg a) (neg b))

-- Bool instance:
wedge _ = (&&)`,
      mode: 'tarski',
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
      haskellDef: `-- class Monad m
return :: a -> m a

-- lifts pure Omega into M frmwk (Omega frmwk)
-- Identity: return = Identity
-- Dist: return = certainly`,
      mode: 'kleisli',
      inputs: [{ id: 'return-in', label: 'Omega', position: 'left' }],
      outputs: [{ id: 'return-out', label: 'M(Omega)', position: 'right' }],
    },
  ],

  copies: [],

  wires: [
    // Point -> labelA and classifierA
    { id: 'w-pt-labelA', sourceBox: 'in-pt', sourcePort: 'in-pt', targetBox: 'labelA', targetPort: 'labelA-in-pt', wireType: 'Point', isMonadic: false },
    { id: 'w-pt-classA', sourceBox: 'in-pt', sourcePort: 'in-pt', targetBox: 'classifierA', targetPort: 'classA-in-pt', wireType: 'Point', isMonadic: false },

    // ParamsMLP -> classifierA (from top)
    { id: 'w-mlp-classA', sourceBox: 'in-mlp', sourcePort: 'in-mlp', targetBox: 'classifierA', targetPort: 'classA-in-mlp', wireType: 'ParamsMLP', isMonadic: false },

    // ParamsLogic -> implies-1, implies-2, wedge (from top)
    { id: 'w-lp-imp1', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'implies-1', targetPort: 'imp1-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-imp2', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'implies-2', targetPort: 'imp2-in-lp', wireType: 'ParamsLogic', isMonadic: false },
    { id: 'w-lp-wedge', sourceBox: 'in-lp', sourcePort: 'in-lp', targetBox: 'wedge', targetPort: 'wedge-in-lp', wireType: 'ParamsLogic', isMonadic: false },

    // labelA -> implies-1 and neg-label
    { id: 'w-label-imp1', sourceBox: 'labelA', sourcePort: 'labelA-out', targetBox: 'implies-1', targetPort: 'imp1-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-label-neg', sourceBox: 'labelA', sourcePort: 'labelA-out', targetBox: 'neg-label', targetPort: 'neg-label-in', wireType: 'Omega', isMonadic: false },

    // classifierA -> implies-1 and neg-pred
    { id: 'w-pred-imp1', sourceBox: 'classifierA', sourcePort: 'classA-out', targetBox: 'implies-1', targetPort: 'imp1-in-b', wireType: 'Omega', isMonadic: false },
    { id: 'w-pred-neg', sourceBox: 'classifierA', sourcePort: 'classA-out', targetBox: 'neg-pred', targetPort: 'neg-pred-in', wireType: 'Omega', isMonadic: false },

    // neg -> implies-2
    { id: 'w-neg-label-imp2', sourceBox: 'neg-label', sourcePort: 'neg-label-out', targetBox: 'implies-2', targetPort: 'imp2-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-neg-pred-imp2', sourceBox: 'neg-pred', sourcePort: 'neg-pred-out', targetBox: 'implies-2', targetPort: 'imp2-in-b', wireType: 'Omega', isMonadic: false },

    // implies -> wedge
    { id: 'w-imp1-wedge', sourceBox: 'implies-1', sourcePort: 'imp1-out', targetBox: 'wedge', targetPort: 'wedge-in-a', wireType: 'Omega', isMonadic: false },
    { id: 'w-imp2-wedge', sourceBox: 'implies-2', sourcePort: 'imp2-out', targetBox: 'wedge', targetPort: 'wedge-in-b', wireType: 'Omega', isMonadic: false },

    // wedge -> return
    { id: 'w-wedge-return', sourceBox: 'wedge', sourcePort: 'wedge-out', targetBox: 'return', targetPort: 'return-in', wireType: 'Omega', isMonadic: false },

    // return -> output
    { id: 'w-return-out', sourceBox: 'return', sourcePort: 'return-out', targetBox: 'out-omega', targetPort: 'out-omega', wireType: 'M(Omega)', isMonadic: false },
  ],
}
