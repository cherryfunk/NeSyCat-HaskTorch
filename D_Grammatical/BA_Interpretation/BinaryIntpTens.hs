{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in FrmwkGeom (TENS + Identity).
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import A_Categorical.BA_Interpretation.StarIntp (FrmwkGeom)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (runIdentity)
import qualified Torch

-- | Binary axiom in FrmwkGeom (TENS + Identity).
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega FrmwkGeom
binaryAxiomTens betaT domain paramMLP =
  runIdentity (binarySentence @FrmwkGeom betaT domain paramMLP)
