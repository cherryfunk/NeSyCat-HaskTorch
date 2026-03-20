{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Abstract binary classification formula.
--   Written once, polymorphic over the category.
--   Instantiate at @DATA or @TENS to get the concrete formula.
--
--   POINTWISE PREDICATE (functorial action: X^n -> Y^n)
--   The quantifier aggregation (Y^n -> Y) lives in F_Interpretation.
module D_Grammatical.D_Theory.BinaryFormulas
  ( binaryPredicate,
  )
where

import B_Logical.D_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.D_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))

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
