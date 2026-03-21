{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Abstract binary classification formula.
--   Written once, polymorphic over the type system (cat) and monad (m).
--
--   The Kleisli-lifted quantifier bigWedgeKl decomposes as:
--     I(Q)^M . com . Lambda(phi)
--   where com = sequence (Haskell's Traversable commutator).
module D_Grammatical.B_Theory.BinaryFormulas
  ( binaryPredicate,
    binarySentence,
    binarySentenceTens,
    bigWedgeKl,
  )
where

import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import Data.Functor.Identity (Identity, runIdentity)

-- | Kleisli-lifted universal quantifier.
--   Decomposes as: I(bigWedge)^M . com . Lambda(phi)
--     1. map phi        -- functorial action
--     2. sequence       -- commutator (inside mapM)
--     3. fmap fold      -- lifted fold with wedge
bigWedgeKl ::
  (TwoMonBLatTheory dom tau, Monad m) =>
  ParamsLogic tau ->
  [a] ->
  (a -> m tau) ->
  m tau
bigWedgeKl lp pts phi = do
  omegas <- mapM phi pts
  return (foldr (wedge lp) top omegas)

-- | Abstract pointwise predicate for binary classification:
--     (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
--
--   Polymorphic over type system (cat) and monad (m).
--   ParamsMLP (theta) is external (from Para), curried in.
binaryPredicate ::
  forall cat m.
  ( BinaryKlFun cat m,
    TwoMonBLatTheory cat (Omega cat),
    Monad m
  ) =>
  ParamsLogic (Omega cat) ->
  ParamsMLP ->
  Point cat ->
  m (Omega cat)
binaryPredicate lp paramMLP pt = do
  pred <- classifierA @cat @m paramMLP pt
  let label = labelA @cat pt
  return (wedge lp (implies lp label pred) (implies lp (neg label) (neg pred)))

-- | Sentence: forall x. phi(x) via Kleisli-lifted quantifier.
--   Works for any monad m (Dist, Identity, Giry, ...).
--   Uses bigWedgeKl (the Kleisli lift of bigWedge).
binarySentence ::
  forall cat m.
  ( BinaryKlFun cat m,
    TwoMonBLatTheory cat (Omega cat),
    Monad m
  ) =>
  ParamsLogic (Omega cat) ->
  [Point cat] ->
  ParamsMLP ->
  m (Omega cat)
binarySentence lp pts paramMLP =
  bigWedgeKl lp pts (binaryPredicate @cat @m lp paramMLP)

-- | TENS-specific sentence using the pure vectorized bigWedge.
--   For the geometry paradigm where m = Identity and the quantifier
--   operates on TensorBatch via batched LogSumExp (not point-by-point).
binarySentenceTens ::
  forall cat.
  ( BinaryKlFun cat Identity,
    TwoMonBLatTheory cat (Omega cat),
    A2MonBLatTheory cat (Omega cat)
  ) =>
  ParamsLogic (Omega cat) ->
  cat (Point cat) ->
  ParamsMLP ->
  Omega cat
binarySentenceTens lp dom paramMLP =
  bigWedge lp dom (\_ -> top) (\pt -> runIdentity (binaryPredicate @cat @Identity lp paramMLP pt))
