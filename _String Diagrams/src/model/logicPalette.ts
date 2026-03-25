import type { MorphismDef } from './types'

// Pre-defined logic operations from TwoMonBLatTheory and A2MonBLatTheory.
// These are the ONLY operations allowed in the logic layer (after Omega).
// Each entry is a template -- instantiated with a unique ID when added to a diagram.

export const LOGIC_PALETTE: Omit<MorphismDef, 'id'>[] = [
  // --- TwoMonBLatTheory U tau ---
  {
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
      { id: 'in-a', label: 'Omega', position: 'left' },
      { id: 'in-b', label: 'Omega', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'Omega', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },
  {
    label: 'vee',
    haskellSig: 'vee :: ParamsLogic tau -> tau -> tau -> tau',
    haskellClass: 'TwoMonBLatTheory U tau',
    instances: [
      { universe: 'Bool', def: 'vee _ = (||)' },
      { universe: 'Tensor', def: 'vee betaT a b = logsumexp(a*beta, b*beta) / beta' },
    ],
    mode: 'tarski',
    layer: 'logical',
    inputs: [
      { id: 'in-a', label: 'Omega', position: 'left' },
      { id: 'in-b', label: 'Omega', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'Omega', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },
  {
    label: 'neg',
    haskellSig: 'neg :: tau -> tau',
    haskellClass: 'TwoMonBLatTheory U tau',
    instances: [
      { universe: 'Bool', def: 'neg = not' },
      { universe: 'Tensor', def: 'neg a = UnsafeMkTensor (negate (toDynamic a))' },
    ],
    mode: 'tarski',
    layer: 'logical',
    inputs: [{ id: 'in', label: 'Omega', position: 'left' }],
    outputs: [{ id: 'out', label: 'Omega', position: 'right' }],
  },
  {
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
      { id: 'in-a', label: 'Omega', position: 'left' },
      { id: 'in-b', label: 'Omega', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'Omega', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },
  {
    label: 'oplus',
    haskellSig: 'oplus :: ParamsLogic tau -> tau -> tau -> tau',
    haskellClass: 'TwoMonBLatTheory U tau',
    instances: [],
    mode: 'tarski',
    layer: 'logical',
    inputs: [
      { id: 'in-a', label: 'Omega', position: 'left' },
      { id: 'in-b', label: 'Omega', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'Omega', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },
  {
    label: 'otimes',
    haskellSig: 'otimes :: ParamsLogic tau -> tau -> tau -> tau',
    haskellClass: 'TwoMonBLatTheory U tau',
    instances: [],
    mode: 'tarski',
    layer: 'logical',
    inputs: [
      { id: 'in-a', label: 'Omega', position: 'left' },
      { id: 'in-b', label: 'Omega', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'Omega', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },

  // --- A2MonBLatTheory a U tau (guarded quantifiers) ---
  {
    label: 'bigWedge',
    haskellSig: 'bigWedge :: ParamsLogic tau -> Guard U a -> (a -> M U tau) -> M U tau',
    haskellClass: 'A2MonBLatTheory a U tau',
    instances: [
      { universe: 'Bool (MeasU)', def: 'bigWedge _ guard phi = do\n  omegas <- mapM phi guard\n  return (foldl (wedge ()) True omegas)' },
      { universe: 'Tensor (GeomU)', def: 'bigWedge betaT guard phi = ... (smooth min via LogSumExp)' },
    ],
    mode: 'tarski',
    layer: 'logical',
    inputs: [
      { id: 'in-guard', label: 'Guard', position: 'left' },
      { id: 'in-pred', label: 'a -> M U tau', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'M(Omega)', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },
  {
    label: 'bigVee',
    haskellSig: 'bigVee :: ParamsLogic tau -> Guard U a -> (a -> M U tau) -> M U tau',
    haskellClass: 'A2MonBLatTheory a U tau',
    instances: [
      { universe: 'Bool (MeasU)', def: 'bigVee _ guard phi = do\n  omegas <- mapM phi guard\n  return (foldl (vee ()) False omegas)' },
    ],
    mode: 'tarski',
    layer: 'logical',
    inputs: [
      { id: 'in-guard', label: 'Guard', position: 'left' },
      { id: 'in-pred', label: 'a -> M U tau', position: 'left' },
    ],
    outputs: [{ id: 'out', label: 'M(Omega)', position: 'right' }],
    paramInputs: [{ id: 'in-lp', label: 'ParamsLogic', position: 'top' }],
  },

  // --- Structural ---
  {
    label: 'return',
    haskellSig: 'return :: Monad m => a -> m a',
    haskellClass: 'Monad m',
    instances: [
      { universe: 'Identity', def: 'return = Identity' },
      { universe: 'Dist', def: 'return = certainly' },
    ],
    mode: 'kleisli',
    layer: 'logical',
    inputs: [{ id: 'in', label: 'Omega', position: 'left' }],
    outputs: [{ id: 'out', label: 'M(Omega)', position: 'right' }],
  },
]
