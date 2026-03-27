{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Abstract binary classification formula.
--   Uses bigWedge from A2MonBLatTheory for quantification.
--   Works for any universe (GeomU, MeasU, etc.).
module D_Grammatical.B_Theory.BinaryFormulas
  ( binaryPredicate,
    binarySentence,
  )
where

import A_Categorical.B_Theory.StarTheory (Universe (..))
import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..), Guard)
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)

-- | Abstract pointwise predicate for binary classification.
binaryPredicate ::
  forall u.
  ( BinaryKlFun u,
    TwoMonBLatTheory u (Omega u),
    Monad (M u)
  ) =>
  ParamsLogic (Omega u) ->
  ParamsMLP ->
  Point u ->
  M u (Omega u)
binaryPredicate lp paramMLP pt = do
  pred <- classifierA @u paramMLP pt
  let label = labelA @u pt
  return (wedge lp (implies lp label pred) (implies lp (neg label) (neg pred)))

-- | Sentence: forall x in S. phi(x) -- a guarded quantifier.
--   The guard (Guard u a) specifies the subset S to quantify over.
--   The predicate (binaryPredicate) is pointwise on elements of type a.
binarySentence ::
  forall u a.
  ( BinaryKlFun u,
    TwoMonBLatTheory u (Omega u),
    A2MonBLatTheory a u (Omega u),
    Monad (M u),
    a ~ Point u
  ) =>
  ParamsLogic (Omega u) ->
  Guard u a ->
  ParamsMLP ->
  M u (Omega u)
binarySentence lp guard paramMLP =
  bigWedge lp guard
    (binaryPredicate @u lp paramMLP)
