{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in DATA + Dist.
--   Kleisli lift: commutator (mapM) + fold with wedge from TwoMonBLatTheory.
module D_Grammatical.BA_Interpretation.BinaryIntpData
  ( binaryAxiomData,
  )
where

import B_Logical.BA_Interpretation.Boolean ()
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.C_TypeSystem.Data (DATA)
import C_Domain.B_Theory.BinaryTheory (BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import C_Domain.BA_Interpretation.BinaryReal ()
import A_Categorical.DA_Realization.Dist (Dist)
import D_Grammatical.B_Theory.BinaryFormulas (binaryPredicate)

-- | Binary axiom in DATA + Dist.
--   Kleisli lift: commutator (mapM) + fold (wedge from theory).
binaryAxiomData :: [Point DATA] -> ParamsMLP -> Dist (Omega DATA)
binaryAxiomData pts paramMLP = do
  omegas <- mapM (binaryPredicate @DATA @Dist () paramMLP) pts
  return (foldr (wedge ()) top omegas)
