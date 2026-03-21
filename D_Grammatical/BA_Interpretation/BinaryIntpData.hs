{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in DATA + Dist.
--
--   Each classifierA @DATA @Dist returns Dist Bool (via the bridge).
--   The result is Dist Bool: the probability that the formula is satisfied.
module D_Grammatical.BA_Interpretation.BinaryIntpData
  ( binaryAxiomData,
  )
where

import B_Logical.BA_Interpretation.Boolean ()           -- TwoMonBLatTheory Bool instance
import C_Domain.C_TypeSystem.Data (DATA (..))
import C_Domain.B_Theory.BinaryTheory (BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import C_Domain.BA_Interpretation.BinaryReal ()         -- BinaryKlFun DATA Dist instance
import A_Categorical.DA_Realization.Dist (Dist)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentenceM)

-- | Binary axiom evaluated in DATA + Dist.
binaryAxiomData :: [Point DATA] -> ParamsMLP -> Dist (Omega DATA)
binaryAxiomData pts paramMLP = binarySentenceM @DATA @Dist () pts paramMLP
