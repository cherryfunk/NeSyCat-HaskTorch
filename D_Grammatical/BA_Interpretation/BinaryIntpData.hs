{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in DATA.
--
--   Evaluates the abstract formula in the DATA category:
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
--
--   Each classifierA @DATA returns Dist Bool (via the bridge: enc -> MLP -> dec).
--   The result is Dist Bool: the probability that the formula is satisfied.
module D_Grammatical.BA_Interpretation.BinaryIntpData
  ( binaryAxiomData,
  )
where

import B_Logical.BA_Interpretation.Boolean ()           -- TwoMonBLatTheory Bool instance
import C_Domain.A_Category.Data (DATA (..))
import C_Domain.B_Theory.BinaryTheory (BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()         -- BinaryKlFun DATA instance
import D_Grammatical.B_Theory.BinaryFormulas (binarySentenceM)

-- | Binary axiom evaluated in DATA category.
--   Returns Dist Bool: probability that the formula is satisfied.
binaryAxiomData :: [Point DATA] -> ParamsDomain DATA -> M DATA (Omega DATA)
binaryAxiomData pts params = binarySentenceM @DATA () pts params
