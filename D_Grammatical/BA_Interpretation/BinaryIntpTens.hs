{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   Same as DATA: predicate + quantifier via binarySentence.
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS + Identity.
--   Same as binaryAxiomData: predicate per point, quantifier reduces.
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  let n = head (Torch.shape dataTensor)
      -- Individual points as [1,2] tensors
      points = [ UnsafeMkTensor (Torch.sliceDim 0 i (i+1) 1 dataTensor) :: Point TENS
               | i <- [0..n-1] ]
   in runIdentity (binarySentence @TENS @Identity betaT points paramMLP)
