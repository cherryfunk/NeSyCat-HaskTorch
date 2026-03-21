{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Abstract binary classification formula.
--   Written once, polymorphic over the type system (cat) and monad (m).
--   Instantiate at @DATA @Dist or @TENS @Identity to get the concrete formula.
module D_Grammatical.B_Theory.BinaryFormulas
  ( binaryPredicate,
    binarySentence,
    binarySentenceM,
  )
where

import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import Data.Functor.Identity (Identity, runIdentity)

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

-- | Full sentence: forall x. phi(x) with canonical measure.
--   For deterministic monads (m ~ Identity).
binarySentence ::
  forall cat.
  ( BinaryKlFun cat Identity,
    TwoMonBLatTheory cat (Omega cat),
    A2MonBLatTheory cat (Omega cat)
  ) =>
  ParamsLogic (Omega cat) ->
  cat (Point cat) ->
  ParamsMLP ->
  Omega cat
binarySentence lp dom paramMLP =
  bigWedge lp dom (\_ -> top) (\pt -> runIdentity (binaryPredicate @cat @Identity lp paramMLP pt))

-- | Monadic sentence: forall x. phi(x) when m is a proper monad (e.g. Dist).
binarySentenceM ::
  forall cat m.
  ( BinaryKlFun cat m,
    TwoMonBLatTheory cat (Omega cat),
    Monad m
  ) =>
  ParamsLogic (Omega cat) ->
  [Point cat] ->
  ParamsMLP ->
  m (Omega cat)
binarySentenceM lp pts paramMLP = do
  omegas <- mapM (binaryPredicate @cat @m lp paramMLP) pts
  return (foldr (wedge lp) top omegas)
