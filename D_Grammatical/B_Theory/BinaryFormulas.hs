{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Abstract binary classification formula.
--   Uses bigWedge from A2MonBLatTheory for quantification.
--   Works for any framework (FrmwkGeom, FrmwkMeas, etc.).
module D_Grammatical.B_Theory.BinaryFormulas
  ( binaryPredicate,
    binarySentence,
  )
where

import A_Categorical.B_Theory.StarTheory (Framework (..))
import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)

-- | Abstract pointwise predicate for binary classification.
binaryPredicate ::
  forall frmwk.
  ( BinaryKlFun frmwk,
    TwoMonBLatTheory frmwk (Omega frmwk),
    Monad (Mon frmwk)
  ) =>
  ParamsLogic (Omega frmwk) ->
  ParamsMLP ->
  Point frmwk ->
  Mon frmwk (Omega frmwk)
binaryPredicate lp paramMLP pt = do
  pred <- classifierA @frmwk paramMLP pt
  let label = labelA @frmwk pt
  return (wedge lp (implies lp label pred) (implies lp (neg label) (neg pred)))

-- | Sentence: forall x. phi(x) via bigWedge from the theory.
--   Works for any framework. The quantifier (bigWedge) handles
--   both the monadic predicate and the reduction.
binarySentence ::
  forall frmwk a.
  ( BinaryKlFun frmwk,
    TwoMonBLatTheory frmwk (Omega frmwk),
    A2MonBLatTheory a frmwk (Omega frmwk),
    Monad (Mon frmwk),
    a ~ Point frmwk
  ) =>
  ParamsLogic (Omega frmwk) ->
  Domain a ->
  ParamsMLP ->
  Mon frmwk (Omega frmwk)
binarySentence lp domain paramMLP =
  bigWedge @a @frmwk @(Omega frmwk) lp domain
    (binaryPredicate @frmwk lp paramMLP)
