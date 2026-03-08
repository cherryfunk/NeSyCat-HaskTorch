{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE InstanceSigs #-}

module A2_Interpretation.B2_Typological.Categories.TENS where

import GHC.TypeLits (Nat)
import Torch.Typed.Tensor (Tensor, toDynamic)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))

-- | Eq for typed Tensors: device-polymorphic.
--   Delegates to the untyped Torch.Tensor Eq via toDynamic.
instance Eq (Tensor device dtype shape) where
  (==) :: Tensor device dtype shape -> Tensor device dtype shape -> Bool
  a == b = toDynamic a == toDynamic b

-- | Ord for typed Tensors: device-polymorphic, shape-polymorphic.
--   Flattens to 1D before comparing element-wise.
instance Ord (Tensor device dtype shape) where
  compare a b =
    let flatA = Torch.reshape [-1] (toDynamic a)
        flatB = Torch.reshape [-1] (toDynamic b)
    in compare (Torch.asValue flatA :: [Float]) (Torch.asValue flatB :: [Float])

-- | Objects of TENS: shape-indexed tensor spaces.
--   The TensorSpace constructor witnesses that every valid TENS object supports Eq and Ord.
data TENS a where
  TensorSpace :: (Eq (Tensor d dt s), Ord (Tensor d dt s))
              => TENS (Tensor d dt s) -- R^shape, with Eq/Ord evidence
  TensProd :: TENS a -> TENS b -> TENS (a, b)
  TensUnit :: TENS ()
