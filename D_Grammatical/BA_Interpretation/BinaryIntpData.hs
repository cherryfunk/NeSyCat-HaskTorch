{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in FrmwkMeas (DATA + Dist).
module D_Grammatical.BA_Interpretation.BinaryIntpData
  ( binaryAxiomData,
  )
where

import A_Categorical.B_Theory.StarTheory (Framework (..))
import A_Categorical.BA_Interpretation.StarIntp (FrmwkMeas)
import B_Logical.BA_Interpretation.Boolean ()
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import C_Domain.BA_Interpretation.BinaryReal ()
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)

-- | Binary axiom in FrmwkMeas (DATA + Dist).
--   Evaluates the formula probabilistically (Mon = Dist).
--   Not used in the benchmark (which trains via binaryAxiomTens in FrmwkGeom,
--   then evaluates pointwise via classifierA @FrmwkMeas).
--   Available for probabilistic reasoning about axiom satisfaction.
binaryAxiomData :: [Point FrmwkMeas] -> ParamsMLP -> M FrmwkMeas (Omega FrmwkMeas)
binaryAxiomData domain paramMLP = binarySentence @FrmwkMeas () domain paramMLP
