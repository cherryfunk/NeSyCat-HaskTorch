{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in MeasU (DATA + Dist).
module D_Grammatical.BA_Interpretation.BinaryIntpData
  ( binaryAxiomData,
  )
where

import A_Categorical.B_Theory.StarTheory (Universe (..))
import A_Categorical.BA_Interpretation.StarIntp (MeasU)
import B_Logical.BA_Interpretation.Boolean ()
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import C_Domain.BA_Interpretation.BinaryReal ()
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)

-- | Binary axiom in MeasU (DATA + Dist).
--   Evaluates the formula probabilistically (Mon = Dist).
--   Guard is [Point MeasU] = [(Float, Float)] — a finite subset of R^2.
binaryAxiomData :: [Point MeasU] -> ParamsMLP -> M MeasU (Omega MeasU)
binaryAxiomData guard paramMLP = binarySentence @MeasU () guard paramMLP
