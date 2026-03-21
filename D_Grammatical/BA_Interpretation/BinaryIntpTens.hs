{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   Same as DATA: takes [Point TENS], applies binarySentence.
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
    binaryAxiomTensWrap,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS)
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom evaluated in TENS + Identity.
binaryAxiomTens :: ParamsLogic (Omega TENS) -> [Point TENS] -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT pts paramMLP = runIdentity (binarySentence @TENS @Identity betaT pts paramMLP)

-- | Wrapper: converts a raw batch tensor to [Point TENS] for the training loop.
binaryAxiomTensWrap :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTensWrap betaT dataTensor paramMLP =
  let n = head (Torch.shape dataTensor)
      points = [ UnsafeMkTensor (Torch.sliceDim 0 i (i+1) 1 dataTensor) :: Point TENS
               | i <- [0..n-1] ]
   in binaryAxiomTens betaT points paramMLP
