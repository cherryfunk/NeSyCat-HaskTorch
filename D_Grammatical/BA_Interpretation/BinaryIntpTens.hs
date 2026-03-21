{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   The formula (binaryPredicate) takes one Point TENS.
--   PyTorch broadcasts: a batch [N,2] works as a single input.
--   The quantifier (forall via LogSumExp) reduces [N,1] -> [1].
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS)
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import D_Grammatical.B_Theory.BinaryFormulas (binaryPredicate)
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS + Identity.
--   Pass the batch tensor straight through the formula (PyTorch broadcasts).
--   Then apply the quantifier (forall = smooth min via LogSumExp).
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  let -- Formula: one call, PyTorch handles the batch dimension automatically
      pt = UnsafeMkTensor dataTensor :: Point TENS
      batchOmegas = runIdentity (binaryPredicate @TENS @Identity betaT paramMLP pt)
      -- Quantifier: forall x. phi(x) = not (exists x. not phi(x))
      --   exists = (1/beta) * logsumexp(beta * phi) - log(N)
      n = head (Torch.shape dataTensor)
      negOmegas = toDynamic (neg batchOmegas)
      lse = F.logsumexp (negOmegas `Torch.mul` betaT) 0 False
      forallResult = negate ((lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT)
   in UnsafeMkTensor (Torch.reshape [1] forallResult)
