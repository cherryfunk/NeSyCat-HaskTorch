{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Abstract binary classification formula.
--   Written once, polymorphic over the category.
--   Instantiate at @DATA or @TENS to get the concrete formula.
--
--   POINTWISE PREDICATE: X -> Omega  (functorial action: X^n -> Omega^n)
--   SENTENCE:            forall x. phi(x)   (quantifier from A2MonBLatTheory)
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
--   i.e. "the classifier agrees with the label."
--
--   ParamsMLP (theta) is external (from Para), curried in.
binaryPredicate ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory cat (Omega cat),
    Monad (M cat)
  ) =>
  ParamsLogic (Omega cat) ->
  ParamsMLP ->
  Point cat ->
  M cat (Omega cat)
binaryPredicate lp paramMLP pt = do
  pred <- classifierA @cat paramMLP pt
  let label = labelA @cat pt
  return (wedge lp (implies lp label pred) (implies lp (neg label) (neg pred)))

-- | Full sentence: forall x. phi(x) with canonical measure.
binarySentence ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory cat (Omega cat),
    A2MonBLatTheory cat (Omega cat),
    M cat ~ Identity
  ) =>
  ParamsLogic (Omega cat) ->
  cat (Point cat) ->
  ParamsMLP ->
  Omega cat
binarySentence lp dom paramMLP =
  bigWedge lp dom (\_ -> top) (\pt -> runIdentity (binaryPredicate @cat lp paramMLP pt))

-- | Monadic sentence: forall x. phi(x) when M cat is a proper monad (e.g. Dist).
binarySentenceM ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory cat (Omega cat),
    Monad (M cat)
  ) =>
  ParamsLogic (Omega cat) ->
  [Point cat] ->
  ParamsMLP ->
  M cat (Omega cat)
binarySentenceM lp pts paramMLP = do
  omegas <- mapM (binaryPredicate @cat lp paramMLP) pts
  return (foldr (wedge lp) top omegas)
