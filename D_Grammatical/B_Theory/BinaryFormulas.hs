{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Abstract binary classification formula.
--   Uses bigWedge from A2MonBLatTheory for quantification.
module D_Grammatical.B_Theory.BinaryFormulas
  ( binaryPredicate,
    binarySentence,
  )
where

import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import Data.Functor.Identity (Identity, runIdentity)

-- | Abstract pointwise predicate for binary classification.
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

-- | Sentence: forall x. phi(x) via bigWedge from the theory.
--   For Identity monad: unwrap to pure predicate, apply bigWedge directly.
--   The domain is passed through from the axiom file.
binarySentence ::
  forall cat a.
  ( BinaryKlFun cat Identity,
    TwoMonBLatTheory cat (Omega cat),
    A2MonBLatTheory a cat (Omega cat),
    a ~ Point cat
  ) =>
  ParamsLogic (Omega cat) ->
  Domain a ->
  ParamsMLP ->
  Omega cat
binarySentence lp domain paramMLP =
  bigWedge @a @cat @(Omega cat) lp domain
    (\pt -> runIdentity (binaryPredicate @cat @Identity lp paramMLP pt))
