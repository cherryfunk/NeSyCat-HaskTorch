{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensUniform).
module D_Grammatical.C_Category.BinaryFormulasUniform
  ( axiomUniform,
  )
where

import C_NonLogical.A_Signature.BinarySig (Binary_Sig (classifierA, labelA))
import B_Logical.C_Category.DATA (DATA (..))
import B_Logical.C_Category.TENS (TENS (..))
import B_Logical.C_Category.TensUniform (Omega, bigWedgeU, negU, wedge)
import C_NonLogical.C_Category.BinaryUniformMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import C_NonLogical.C_Category.BinaryUniform ()
import Data.Functor.Identity (runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | The pure logical axiom for TensUniform (Binary_MLP with sigmoid).
axiomUniform :: Torch.Tensor -> Binary_MLP -> Omega
axiomUniform dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      forallPos = bigWedgeU labels preds
      forallNeg = bigWedgeU (negU labels) (negU preds)
   in forallPos `wedge` forallNeg
