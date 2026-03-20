{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS.
--
--   Instantiates the abstract binaryPredicate at @TENS and adds
--   the ∀ quantifier aggregation (bigWedgeR) over data points.
--
--   TENS INTERPRETATION: quantifier ∀ is interpreted as bigWedgeR (LogSumExp).
--   This is an Eilenberg-Moore algebra map for the empirical measure.
--
--   The abstract formula works correctly because:
--     • classifierA @TENS returns ℝ logits
--     • labelA @TENS returns ℝ logits (±scale, not {0,1})
--     • TwoMonBLatTheory Omega uses ℝ logic (neg = -x, vee = LogSumExp)
--   So implies(±∞, pred) correctly gives pred (true antecedent)
--   or +∞ (false antecedent = vacuously true).
module D_Grammatical.F_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
    binaryAxiomTensBeta,
  )
where

import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.TensReal (bigWedgeR)
import B_Logical.F_Interpretation.TensRealBeta (bigWedgeRBeta)
import C_Domain.D_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.F_Interpretation.BinaryReal ()
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
import D_Grammatical.D_Theory.BinaryFormulas (binaryPredicate)
import Data.Functor.Identity (runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS:
--     ∀x. binaryPredicate(x)
--   = ∀x. (label(x) → pred(x)) ∧ (¬label(x) → ¬pred(x))
--
--   Instantiates the abstract binaryPredicate at @TENS,
--   then aggregates over all data points via bigWedgeR.
binaryAxiomTens :: Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTens dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      pointwise = runIdentity (binaryPredicate @TENS m pt)
      pw = toDynamic pointwise
      ones = Torch.onesLike pw
   in bigWedgeR ones pw

-- | Beta-parameterized variant: same abstract predicate,
--   but the ∀ quantifier uses learnable beta (LogSumExp sharpness).
binaryAxiomTensBeta :: Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTensBeta betaT dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      pointwise = runIdentity (binaryPredicate @TENS m pt)
      pw = toDynamic pointwise
      ones = Torch.onesLike pw
   in bigWedgeRBeta betaT ones pw
