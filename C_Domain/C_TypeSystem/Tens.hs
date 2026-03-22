{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | The TENS type system (geometry paradigm).
--   TensObj type class replaces the old TENS GADT.
module C_Domain.C_TypeSystem.Tens
  ( TensObj (..),
  )
where

import Numeric.Natural (Natural)
import qualified Torch
import Torch.Typed.Tensor (Tensor, toDynamic)

-- | Eq for typed Tensors: device-polymorphic.
instance Eq (Tensor device dtype shape) where
  (==) :: Tensor device dtype shape -> Tensor device dtype shape -> Bool
  a == b = toDynamic a == toDynamic b

-- | Type membership in the TENS type system.
class TensObj a

instance TensObj (Tensor d dt s)
instance (TensObj a, TensObj b) => TensObj (a, b)
instance TensObj ()
instance TensObj Natural
