{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS.
--   Instantiates the abstract formula at @TENS and adds
--   the ∀ quantifier aggregation (bigWedgeR) over data points.
module D_Grammatical.F_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
  )
where

import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.TensReal (bigWedgeR)
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
      -- Instantiate abstract formula at @TENS (pointwise, returns Identity)
      pointwise = runIdentity (binaryPredicate @TENS m pt)
      -- Unwrap to dynamic tensor for batch aggregation
      pw = toDynamic pointwise
      -- ∀ quantifier: aggregate over all data points
      ones = Torch.onesLike pw
   in bigWedgeR ones pw
