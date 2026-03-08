{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}

module A2_Interpretation.B2_Typological.Categories.TENS where

import GHC.TypeLits (Nat)
import Torch.Typed.Tensor (Tensor)

-- | Objects of TENS: shape-indexed tensor spaces.
data TENS a where
  TensorSpace :: TENS (Tensor device dtype shape) -- R^shape
  TensProd :: TENS a -> TENS b -> TENS (a, b)
  TensUnit :: TENS ()
