{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS.
--
--   Instantiates the abstract binarySentence at @TENS, providing the
--   concrete batch as the domain object (TensorBatch).
--
--   TENS INTERPRETATION: quantifier ∀ is interpreted as bigWedge (LogSumExp).
--   This comes from the A2MonBLatTheory TENS Omega instance.
module D_Grammatical.F_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
    binaryAxiomTensBeta,
  )
where

import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.TensRealBeta (bigWedgeRBeta)
import C_Domain.D_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.F_Interpretation.BinaryReal ()
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
import D_Grammatical.D_Theory.BinaryFormulas (binaryPredicate, binarySentence)
import Data.Functor.Identity (runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS:
--     ∀x. binaryPredicate(x)
--   = ∀x. (label(x) → pred(x)) ∧ (¬label(x) → ¬pred(x))
--
--   The batch tensor IS the domain object in TENS (TensorBatch carries
--   the concrete finite sample for GPU batch processing).
binaryAxiomTens :: Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTens dataTensor m =
  binarySentence @TENS (TensorBatch dataTensor) m

-- | Beta-parameterized variant: same abstract predicate,
--   but the ∀ quantifier uses learnable beta (LogSumExp sharpness).
--   Uses direct bigWedgeRBeta — learnable β requires a parameterized
--   typeclass that doesn't exist yet.
binaryAxiomTensBeta :: Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTensBeta betaT dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      pointwise = runIdentity (binaryPredicate @TENS m pt)
      pw = toDynamic pointwise
      ones = Torch.onesLike pw
   in bigWedgeRBeta betaT ones pw
