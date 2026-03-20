{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation of BinaryFormulas in TENS.
--
--   binaryAxiomTens:     fixed beta — all connectives use betaVal constant.
--   binaryAxiomTensBeta: learnable beta — calls TensRealBeta functions directly.
--
--   Both compute the same abstract formula:
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
module D_Grammatical.F_Interpretation.BinaryIntpTens
  ( binaryAxiomTens,
    binaryAxiomTensBeta,
  )
where

import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.TensRealBeta (wedgeRBeta, impliesRBeta, negR, bigWedgeRBeta)
import C_Domain.D_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.F_Interpretation.BinaryReal ()              -- BinaryFun/KlFun TENS
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
import D_Grammatical.D_Theory.BinaryFormulas (binarySentence)
import Data.Functor.Identity (runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Binary axiom in TENS (fixed beta):
--     forall x. (label(x) -> pred(x)) /\ (not label(x) -> not pred(x))
binaryAxiomTens :: Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTens dataTensor m =
  binarySentence @TENS (TensorBatch dataTensor) m

-- | Binary axiom with learnable beta:
--   Same abstract formula, but every operation uses learnable beta.
--   Calls TensRealBeta functions directly — zero overhead vs fixed-beta path.
binaryAxiomTensBeta :: Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega TENS
binaryAxiomTensBeta betaT dataTensor m =
  let pt    = UnsafeMkTensor dataTensor
      pred  = toDynamic (runIdentity (classifierA @TENS m pt))
      label = toDynamic (labelA @TENS pt)
      ones  = Torch.onesLike pred
      phi   = wedgeRBeta betaT (impliesRBeta betaT label pred)
                                (impliesRBeta betaT (negR label) (negR pred))
   in bigWedgeRBeta betaT ones phi
