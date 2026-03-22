{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in DATA + Dist.
module D_Grammatical.BA_Interpretation.BinaryIntpData
  ( binaryAxiomData,
  )
where

import B_Logical.BA_Interpretation.Boolean ()
import C_Domain.C_TypeSystem.Data (DATA)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import C_Domain.BA_Interpretation.BinaryReal ()
import A_Categorical.DA_Realization.Dist (Dist)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)

-- | Binary axiom in DATA + Dist.
--   Same as TENS: just calls binarySentence.
binaryAxiomData :: [Point DATA] -> ParamsMLP -> Dist (Omega DATA)
binaryAxiomData domain paramMLP = binarySentence @DATA () domain paramMLP
