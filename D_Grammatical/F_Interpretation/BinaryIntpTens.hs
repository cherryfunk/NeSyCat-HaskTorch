{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS.
--
--   Single function: binaryAxiomTens takes beta explicitly.
--   Fixed beta: callers pass Torch.asTensor (1.2 :: Float).
--   Learnable beta: callers pass the learnable tensor.
--
--   Computes the abstract formula:
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
module D_Grammatical.F_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import B_Logical.A_Category.Tens (TENS (..))
import C_Domain.D_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.F_Interpretation.BinaryReal ()              -- BinaryFun/KlFun TENS
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
import D_Grammatical.D_Theory.BinaryFormulas (binarySentence)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS with explicit beta:
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTens betaT dataTensor m =
  binarySentence @TENS betaT (TensorBatch dataTensor) m
