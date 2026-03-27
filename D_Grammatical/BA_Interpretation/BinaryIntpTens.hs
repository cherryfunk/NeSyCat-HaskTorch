{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in GeomU (TENS + Identity).
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import A_Categorical.BA_Interpretation.StarIntp (GeomU)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (runIdentity)
import qualified Torch

-- | Binary axiom in GeomU (TENS + Identity).
--   Guard is Torch.Tensor -- a batch tensor (finite subset of the tensor space).
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega GeomU
binaryAxiomTens betaT guard paramMLP =
  runIdentity (binarySentence @GeomU betaT guard paramMLP)
