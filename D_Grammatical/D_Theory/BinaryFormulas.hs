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
--   SENTENCE:            ∀x. φ(x)   (quantifier from A2MonBLatTheory)
module D_Grammatical.D_Theory.BinaryFormulas
  ( binaryPredicate,
    binarySentence,
  )
where

import B_Logical.D_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.D_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.D_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import Data.Functor.Identity (Identity, runIdentity)

-- | Abstract pointwise predicate for binary classification:
--     (label(x) → pred(x)) ∧ (¬label(x) → ¬pred(x))
--   i.e. "the classifier agrees with the label."
--
--   Works for any category cat that has:
--     • BinaryKlFun cat            (classifierA, labelA)
--     • TwoMonBLatTheory (Omega cat)  (wedge, vee, neg)
--     • Monad (M cat)
binaryPredicate ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory (Omega cat),
    Monad (M cat)
  ) =>
  Params cat ->
  Point cat ->
  M cat (Omega cat)
binaryPredicate params pt = do
  pred <- classifierA @cat params pt
  let label = labelA @cat pt
  return (implies label pred `wedge` implies (neg label) (neg pred))

-- | Full sentence: ∀x. φ(x) with canonical measure.
--   The quantifier bigWedge comes from A2MonBLatTheory — its interpretation
--   depends on the category (LogSumExp for TENS, classical ∀ for DATA).
binarySentence ::
  forall cat.
  ( BinaryKlFun cat,
    TwoMonBLatTheory (Omega cat),
    A2MonBLatTheory cat (Omega cat),
    M cat ~ Identity
  ) =>
  cat (Point cat) ->
  Params cat ->
  Omega cat
binarySentence dom params =
  bigWedge dom (\_ -> top) (\pt -> runIdentity (binaryPredicate @cat params pt))
