{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS.
--
--   Single function: binaryAxiomTens takes beta explicitly.
--   Fixed beta: callers pass Torch.asTensor (1.2 :: Float).
--   Learnable beta: callers pass the learnable tensor.
--
--   Computes the abstract formula:
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()              -- BinaryFun/KlFun TENS
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentenceTens)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS with explicit beta:
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  binarySentenceTens @TENS betaT (TensorBatch dataTensor) paramMLP
