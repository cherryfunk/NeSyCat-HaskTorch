{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensReal).
module D_Grammatical.C_Category.BinaryFormulasReal
  ( axiomReal,
  )
where

import C_NonLogical.A_Signature.BinarySig (Binary_Sig (classifierA, labelA))
import B_Logical.C_Category.DATA (DATA (..))
import B_Logical.C_Category.TENS (TENS (..))
import B_Logical.C_Category.TensReal (bigWedgeR, negR, wedgeR)
import B_Logical.C_Category.TensUniform (Omega)
import C_NonLogical.C_Category.BinaryRealMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import C_NonLogical.C_Category.BinaryReal ()
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
