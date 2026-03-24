{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Abstract binary classification formula.
--   Uses bigWedge from A2MonBLatTheory for quantification.
--   Works for any framework (GeomU, MeasU, etc.).
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
  forall frmwk.
  ( BinaryKlFun frmwk,
    TwoMonBLatTheory frmwk (Omega frmwk),
    Monad (M frmwk)
  ) =>
  ParamsLogic (Omega frmwk) ->
  ParamsMLP ->
  Point frmwk ->
  M frmwk (Omega frmwk)
binaryPredicate lp paramMLP pt = do
  pred <- classifierA @frmwk paramMLP pt
  let label = labelA @frmwk pt
  return (wedge lp (implies lp label pred) (implies lp (neg label) (neg pred)))

-- | Sentence: forall x in S. phi(x) — a guarded quantifier.
--   The guard (Guard frmwk a) specifies the subset S to quantify over.
--   The predicate (binaryPredicate) is pointwise on elements of type a.
binarySentence ::
  forall frmwk a.
  ( BinaryKlFun frmwk,
    TwoMonBLatTheory frmwk (Omega frmwk),
    A2MonBLatTheory a frmwk (Omega frmwk),
    Monad (M frmwk),
    a ~ Point frmwk
  ) =>
  ParamsLogic (Omega frmwk) ->
  Guard frmwk a ->
  ParamsMLP ->
  M frmwk (Omega frmwk)
binarySentence lp guard paramMLP =
  bigWedge lp guard
    (binaryPredicate @frmwk lp paramMLP)
