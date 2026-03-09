{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensReal).
module B_Interpretation.E_Grammatical.BinaryFormulasReal
  ( axiomReal,
  )
where

import A_Syntax.D_NonLogical.BinaryVocab (Binary_Vocab (classifierA, labelA))
import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.C_Logical.TensReal (bigWedgeR, negR, wedgeR)
import B_Interpretation.C_Logical.TensUniform (Omega)
import B_Interpretation.D_NonLogical.BinaryRealMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import B_Interpretation.D_NonLogical.BinaryReal ()
import Data.Functor.Identity (runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | The pure logical axiom for TensReal (Binary_MLP without sigmoid).
axiomReal :: Torch.Tensor -> Binary_MLP -> Omega
axiomReal dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      negLabels = Torch.onesLike labels - labels
      forallPos = bigWedgeR labels preds
      forallNeg = bigWedgeR negLabels (negR preds)
   in UnsafeMkTensor (toDynamic forallPos `wedgeR` toDynamic forallNeg)
