{-# LANGUAGE TypeApplications #-}

-- | Shared axiom formula for Binary Classification (TensUniform).
module B_Interpretation.E_Grammatical.BinaryFormulasUniform
  ( axiomUniform,
  )
where

import A_Syntax.D_NonLogical.BinaryVocab (Binary_Vocab (classifierA, labelA))
import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.C_Logical.TensUniform (Omega, bigWedgeU, negU, wedge)
import B_Interpretation.D_NonLogical.BinaryUniformMLP (Binary_MLP)
-- Instance import (needed for @TENS type family resolution)
import B_Interpretation.D_NonLogical.BinaryUniform ()
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
