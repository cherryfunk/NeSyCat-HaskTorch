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
--   Guard is [Point FrmwkMeas] = [(Float, Float)] — a finite subset of R^2.
binaryAxiomData :: [Point FrmwkMeas] -> ParamsMLP -> M FrmwkMeas (Omega FrmwkMeas)
binaryAxiomData guard paramMLP = binarySentence @FrmwkMeas () guard paramMLP
