{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | Logical interpretation: Tensor-valued Logic (Ω = R^1, a tensor space)
--   Analogous to Real.hs, but all operations are on typed tensors.
module A2_Interpretation.B3_Logical.Tensor where

import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import Torch.Typed.Tensor (Tensor (..), toDynamic)

infixr 3 `wedge`

infixr 2 `vee`

-- | Ω := I(τ) = R^1 (a tensor space)
type Omega = Tensor '( 'CPU, 0) 'Float '[1]

-- | I(⊢) : Comparison
vdash :: Omega -> Omega -> Bool
vdash a b = Torch.asValue (toDynamic a) <= (Torch.asValue (toDynamic b) :: Float)

-- | I(∧) : Meet (min)
wedge :: Omega -> Omega -> Omega
wedge a b =
  let a' = toDynamic a; b' = toDynamic b
   in UnsafeMkTensor ((a' + b' - Torch.abs (a' - b')) / 2)

-- | I(∨) : Join (max)
vee :: Omega -> Omega -> Omega
vee a b =
  let a' = toDynamic a; b' = toDynamic b
   in UnsafeMkTensor ((a' + b' + Torch.abs (a' - b')) / 2)

-- | I(⊥) : Bottom
bot :: Omega
bot = UnsafeMkTensor (Torch.asTensor [(-1.0 / 0.0) :: Float])

-- | I(⊤) : Top
top :: Omega
top = UnsafeMkTensor (Torch.asTensor [(1.0 / 0.0) :: Float])

-- | I(⊕) : Additive monoid
oplus :: Omega -> Omega -> Omega
oplus a b = UnsafeMkTensor (toDynamic a + toDynamic b)

-- | I(⊗) : Multiplicative monoid
otimes :: Omega -> Omega -> Omega
otimes a b = UnsafeMkTensor (toDynamic a * toDynamic b)

-- | I(0) : Additive unit
v0 :: Omega
v0 = UnsafeMkTensor (Torch.asTensor [0.0 :: Float])

-- | I(1) : Multiplicative unit
v1 :: Omega
v1 = UnsafeMkTensor (Torch.asTensor [1.0 :: Float])

-- | I(¬) : Negation (additive inverse)
neg :: Omega -> Omega
neg a = UnsafeMkTensor (Torch.zeros' [1] - toDynamic a)
