{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensReal), β-parameterized.
--
--   Same structure as BinaryFormulasReal.axiomReal, but uses the
--   β-parameterized connectives from TensRealBeta.
module D_Grammatical.D_Interpretation.BinaryFormulasRealBeta
  ( axiomRealBeta,
  )
where

import C_NonLogical.A_Signature.BinarySig (BinaryFuns (classifierA, labelA))
import C_NonLogical.D_Interpretation.DATA (DATA (..))
import B_Logical.D_Interpretation.TENS (TENS (..))
import B_Logical.D_Interpretation.TensRealBeta (bigWedgeRBeta, negR, wedgeRBeta)
import B_Logical.D_Interpretation.TensUniform (Omega)
import C_NonLogical.D_Interpretation.BinaryRealMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import C_NonLogical.D_Interpretation.BinaryReal ()
import Data.Functor.Identity (runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | The pure logical axiom for TensReal (Binary_MLP), parameterized by β.
--
--   axiomRealBeta β dataTensor model  =  ∀⁺(pos → pred) ∧_β ∀⁻(neg → ¬pred)
axiomRealBeta :: Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega
axiomRealBeta betaT dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      negLabels = Torch.onesLike labels - labels
      forallPos = bigWedgeRBeta betaT labels preds
      forallNeg = bigWedgeRBeta betaT negLabels (negR preds)
   in UnsafeMkTensor (wedgeRBeta betaT (toDynamic forallPos) (toDynamic forallNeg))
