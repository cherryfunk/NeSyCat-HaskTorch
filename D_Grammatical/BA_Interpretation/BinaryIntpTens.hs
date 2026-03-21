{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   The formula (binarySentence) produces per-point truth values.
--   The quantifier (forall = smooth min via LogSumExp) aggregates.
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import B_Logical.BA_Interpretation.Tensor (neg)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS + Identity.
--   1. Formula: binarySentence produces [N,1] truth values (per-point, via framework)
--   2. Quantifier: forall x. phi(x) = smooth min via LogSumExp (reduces [N,1] -> [1])
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  let -- Step 1: Apply formula to the batch (goes through classifierA, labelA, connectives)
      pt = UnsafeMkTensor dataTensor :: Point TENS
      batchOmegas = runIdentity (binarySentence @TENS @Identity betaT [pt] paramMLP)
      -- Step 2: Quantifier: forall = not (exists (not phi))
      --   exists phi = (1/beta) * logsumexp(beta * phi) - log(N)
      n = head (Torch.shape dataTensor)
      negOmegas = toDynamic (neg batchOmegas)
      lse = F.logsumexp (negOmegas `Torch.mul` betaT) 0 False
      result = negate ((lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT)
   in UnsafeMkTensor (Torch.reshape [1] result)
