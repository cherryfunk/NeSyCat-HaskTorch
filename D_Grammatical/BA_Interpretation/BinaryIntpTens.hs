{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   Calls binarySentence which uses bigWedge from the theory.
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import qualified Torch

-- | Binary axiom in TENS + Identity.
--   Uses binarySentence with bigWedge from the theory.
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  binarySentence @TENS @(Point TENS) betaT dataTensor paramMLP
