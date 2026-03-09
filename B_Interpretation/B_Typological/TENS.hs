{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

module B_Interpretation.B_Typological.TENS where

import Torch.Typed.Tensor (Tensor, toDynamic)

-- | Eq for typed Tensors: device-polymorphic.
--   Delegates to the untyped Torch.Tensor Eq via toDynamic.
instance Eq (Tensor device dtype shape) where
  (==) :: Tensor device dtype shape -> Tensor device dtype shape -> Bool
  a == b = toDynamic a == toDynamic b

-- | Objects of TENS: shape-indexed tensor spaces.
data TENS a where
  TensorSpace ::
    (Eq (Tensor d dt s)) =>
    TENS (Tensor d dt s) -- R^shape
  TensProd :: TENS a -> TENS b -> TENS (a, b)
  TensUnit :: TENS ()
