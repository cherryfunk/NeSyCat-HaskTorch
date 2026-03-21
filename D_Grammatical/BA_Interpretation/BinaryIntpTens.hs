{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   The LOGIC (connectives, predicate) is per-point.
--   The TRAINING LOOP lifts it to batches by batching the MLP call
--   and applying pointwise connectives on the batch result.
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, hThetaReal)
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import qualified Torch
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS: batched evaluation.
--   The logic is the same per-point formula, but we LIFT it to batches
--   by running the MLP on the whole batch and applying connectives pointwise.
--   This is NOT special-casing — it's the natural lift of the per-point formula.
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  let n = head (Torch.shape dataTensor)
      -- Lift classifierA: batch MLP forward pass [N,2] -> [N,1]
      logits = UnsafeMkTensor (hThetaReal paramMLP dataTensor) :: Omega TENS
      -- Lift labelA: batch label computation [N,2] -> [N,1]
      labels = labelA @TENS (UnsafeMkTensor dataTensor :: Point TENS)
      -- Per-point formula lifted pointwise (connectives are already pointwise on tensors):
      --   phi(x) = (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
      posCase = implies betaT labels logits
      negCase = implies betaT (neg labels) (neg logits)
      batchOmegas = wedge betaT posCase negCase  -- [N,1] batch of truth values
      -- Aggregate: bigWedge = smooth min (De Morgan of LogSumExp)
      --   forall x. phi(x) = not (exists x. not phi(x))
      --   exists x. psi(x) = (1/beta) * logsumexp(beta * psi(x))
      negOmegas = toDynamic (neg batchOmegas)
      lse = F.logsumexp (negOmegas `Torch.mul` betaT) 0 False
      result = negate ((lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT)
   in UnsafeMkTensor (Torch.reshape [1] result)
