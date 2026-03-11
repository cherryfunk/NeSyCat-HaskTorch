{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module A_Categorical.D_Interpretation.Monads.Expectation_TENS (expectTENS) where

import A_Categorical.D_Interpretation.Monads.Giry (Giry (..))
import B_Logical.D_Interpretation.TENS (TENS (..))
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

------------------------------------------------------
-- Integration over TENS (mirrors expect for DATA)
------------------------------------------------------

-- | Expectation over TENS, parameterized by a probability measure (Giry a).
--
--   Mirrors the DATA expectation:
--     expect     :: DATA a -> Giry a -> (a -> Double)        -> Double
--     expectTENS :: TENS a -> Giry a -> (a -> Torch.Tensor)  -> Torch.Tensor
--
--   The Giry parameter IS the probability measure μ.
--   E_μ[φ] = ∫ φ(x) dμ(x)
expectTENS :: TENS a -> Giry a -> (a -> Torch.Tensor) -> Torch.Tensor

-- | Empirical measure: DisUniform over tensor sample points.
--   E_μ[φ] where μ = (1/N) Σᵢ δ(x - xᵢ).
--   Stacks all points into a batch tensor and evaluates φ in one pass.
expectTENS TensorSpace (DisUniform points) phi =
  let stacked = Torch.stack (Torch.Dim 0) (map toDynamic points)
      batchTensor = Torch.toDevice (Torch.Device Torch.CPU 0) stacked
   in phi (UnsafeMkTensor batchTensor)

-- | Categorical measure: weighted sample points.
--   E_μ[φ] = Σᵢ wᵢ · φ(xᵢ)  (weights handled by caller via Tensor.hs)
expectTENS TensorSpace (Categorical points) phi =
  let stacked = Torch.stack (Torch.Dim 0) (map (toDynamic . fst) points)
      batchTensor = Torch.toDevice (Torch.Device Torch.CPU 0) stacked
   in phi (UnsafeMkTensor batchTensor)

-- | Pure (Dirac delta): evaluate at a single point.
expectTENS TensorSpace (Pure x) phi = phi x

expectTENS TensProd {} _ _ = error "expectTENS over TensProd not yet supported"
expectTENS TensUnit _ phi = phi ()

-- Fallback for unsupported Giry constructors
expectTENS _ _ _ = error "expectTENS: unsupported Giry constructor for TENS"
