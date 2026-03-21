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
import Data.Functor.Identity (Identity, runIdentity)

-- | Abstract pointwise predicate for binary classification:
--     (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
--   i.e. "the classifier agrees with the label."
--
--   Works for any category cat that has:
--     * BinaryKlFun cat            (classifierA, labelA)
--     * TwoMonBLatTheory cat (Omega cat)  (wedge, vee, neg)
--     * Monad (M cat)
binaryPredicate ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory cat (Omega cat),
    Monad (M cat)
  ) =>
  ParamsLogic (Omega cat) ->
  ParamsDomain cat ->
  Point cat ->
  M cat (Omega cat)
binaryPredicate lp params pt = do
  pred <- classifierA @cat params pt
  let label = labelA @cat pt
  return (wedge lp (implies lp label pred) (implies lp (neg label) (neg pred)))

-- | Full sentence: forall x. phi(x) with canonical measure.
--   The quantifier bigWedge comes from A2MonBLatTheory -- its interpretation
--   depends on the category (LogSumExp for TENS, classical forall for DATA).
binarySentence ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory cat (Omega cat),
    A2MonBLatTheory cat (Omega cat),
    M cat ~ Identity
  ) =>
  ParamsLogic (Omega cat) ->
  cat (Point cat) ->
  ParamsDomain cat ->
  Omega cat
binarySentence lp dom params =
  bigWedge lp dom (\_ -> top) (\pt -> runIdentity (binaryPredicate @cat lp params pt))

-- | Monadic sentence: forall x. phi(x) when M cat is a proper monad (e.g. Dist).
--   Evaluates the predicate for each point (each may be stochastic),
--   then folds with wedge (conjunction) over all results.
binarySentenceM ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory cat (Omega cat),
    Monad (M cat)
  ) =>
  ParamsLogic (Omega cat) ->
  [Point cat] ->
  ParamsDomain cat ->
  M cat (Omega cat)
binarySentenceM lp pts params = do
  omegas <- mapM (binaryPredicate @cat lp params) pts
  return (foldr (wedge lp) top omegas)
