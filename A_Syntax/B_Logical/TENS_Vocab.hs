{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

module A_Syntax.B_Logical.TENS_Vocab where

import Numeric.Natural (Natural)
import qualified Torch.Tensor
import Torch.Typed.Tensor (Tensor)

-- | Vocabulary for the tensor category TENS.
--   Objects are exactly the types that can appear as domains/codomains
--   in the TENS category: tensor spaces R^shape, finite sets (Natural indices),
--   products, and the unit.
class TensVocab a

-- | Typed tensor spaces R^shape (the core objects)
instance TensVocab (Tensor device dtype shape)

-- | Untyped dynamic tensor (for interop)
instance TensVocab Torch.Tensor.Tensor

-- | Finite sets {0,...,n-1}: dataset index domain (n :: Natural)
instance TensVocab Natural

-- | Finite products (pairs)
instance (TensVocab a, TensVocab b) => TensVocab (a, b)

-- | Terminal object (unit)
instance TensVocab ()
