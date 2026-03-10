{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensReal), β-parameterized.
--
--   Same structure as BinaryFormulasReal.axiomReal, but uses the
--   β-parameterized connectives from TensRealBeta.
module B_Interpretation.D_Grammatical.BinaryFormulasRealBeta
  ( axiomRealBeta,
  )
where

import A_Syntax.C_NonLogical.BinaryVocab (Binary_Vocab (classifierA, labelA))
import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.B_Logical.TensRealBeta (bigWedgeRBeta, negR, wedgeRBeta)
import B_Interpretation.B_Logical.TensUniform (Omega)
import B_Interpretation.C_NonLogical.BinaryRealMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import B_Interpretation.C_NonLogical.BinaryReal ()
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
