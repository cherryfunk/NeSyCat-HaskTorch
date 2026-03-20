{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensReal).
module D_Grammatical.D_Theory.BinaryFormulasReal
  ( axiomReal,
  )
where

import C_Domain.D_Theory.BinaryTheory (BinaryFun (labelA), BinaryKlFun (classifierA))
import C_Domain.A_Category.Data (DATA (..))
import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.TensReal (bigWedgeR, negR, wedgeR)
import B_Logical.F_Interpretation.TensReal (Omega)
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import C_Domain.F_Interpretation.BinaryReal ()
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

ident :: Identity a -> a
ident = runIdentity

-- | The pure logical axiom for TensReal (Binary_MLP without sigmoid).
axiomReal :: Torch.Tensor -> Binary_MLP -> Omega
axiomReal dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic . ident $ classifierA @TENS m pt
      labels = toDynamic (labelA @TENS pt)
      negLabels = Torch.onesLike labels - labels
      forallPos = bigWedgeR labels preds
      forallNeg = bigWedgeR negLabels (negR preds)
   in UnsafeMkTensor (toDynamic forallPos `wedgeR` toDynamic forallNeg)
