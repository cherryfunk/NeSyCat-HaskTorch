{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensReal), beta-parameterized.
--
--   Same structure as BinaryFormulasReal.axiomReal, but uses the
--   beta-parameterized connectives from TensRealBeta.
module D_Grammatical.D_Theory.BinaryFormulasRealBeta
  ( axiomRealBeta,
  )
where

import C_Domain.D_Theory.BinaryTheory (BinaryFun (labelA), BinaryKlFun (classifierA))
import C_Domain.A_Category.Data (DATA (..))
import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.TensRealBeta (bigWedgeRBeta, negR, wedgeRBeta)
import B_Logical.F_Interpretation.TensReal (Omega)
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import C_Domain.F_Interpretation.BinaryReal ()
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

ident :: Identity a -> a
ident = runIdentity

-- | The pure logical axiom for TensReal (Binary_MLP), parameterized by beta.
--
--   axiomRealBeta beta dataTensor model  =  forall⁺(pos -> pred) /\_beta forall⁻(neg -> notpred)
axiomRealBeta :: Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega
axiomRealBeta betaT dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic . ident $ classifierA @TENS m pt
      labels = toDynamic (labelA @TENS pt)
      negLabels = Torch.onesLike labels - labels
      forallPos = bigWedgeRBeta betaT labels preds
      forallNeg = bigWedgeRBeta betaT negLabels (negR preds)
   in UnsafeMkTensor (wedgeRBeta betaT (toDynamic forallPos) (toDynamic forallNeg))
