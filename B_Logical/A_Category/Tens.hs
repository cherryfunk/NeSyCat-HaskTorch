{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

module B_Logical.A_Category.Tens where

import Numeric.Natural (Natural)
import qualified Torch
import Torch.Typed.Tensor (Tensor, toDynamic)

-- | Eq for typed Tensors: device-polymorphic.
instance Eq (Tensor device dtype shape) where
  (==) :: Tensor device dtype shape -> Tensor device dtype shape -> Bool
  a == b = toDynamic a == toDynamic b

-- | Objects of TENS: the tensor category.
data TENS a where
  TensorSpace :: (Eq (Tensor d dt s)) => TENS (Tensor d dt s) -- R^shape
  TensorBatch :: Torch.Tensor -> TENS (Tensor d dt s)         -- concrete finite sample
  TensProd :: TENS a -> TENS b -> TENS (a, b) -- products
  TensUnit :: TENS () -- terminal object
  TensFin :: TENS Natural -- finite index sets