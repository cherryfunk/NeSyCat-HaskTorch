{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS + Identity.
--   Uses the unified binarySentence — processes points individually.
--   The formula is category-agnostic; batching is the training loop's concern.
module D_Grammatical.BA_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import C_Domain.C_TypeSystem.Tens (TENS (..))
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import D_Grammatical.B_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (Identity, runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS: evaluates the formula per point, aggregates.
--   betaT = ParamsLogic (sharpness parameter).
--   dataTensor = [N, 2] batch of training points.
--   The formula runs per point via binarySentence @TENS @Identity.
--   Aggregation (mean of the per-point loss) happens here.
binaryAxiomTens :: Torch.Tensor -> Torch.Tensor -> ParamsMLP -> Omega TENS
binaryAxiomTens betaT dataTensor paramMLP =
  let n = head (Torch.shape dataTensor)
      -- Extract individual points as [1, 2] tensors
      points = [ UnsafeMkTensor (Torch.sliceDim 0 i (i+1) 1 dataTensor) :: Point TENS
               | i <- [0..n-1] ]
      -- Apply formula to each point (Identity monad = deterministic)
      omegas = map (\pt -> runIdentity (binarySentence @TENS @Identity betaT [pt] paramMLP)) points
      -- Aggregate: stack into a tensor and take mean
      omegaTensors = map toDynamic omegas
      stacked = Torch.stack (Torch.Dim 0) omegaTensors
      result = Torch.mean stacked
   in UnsafeMkTensor (Torch.reshape [1] result)
