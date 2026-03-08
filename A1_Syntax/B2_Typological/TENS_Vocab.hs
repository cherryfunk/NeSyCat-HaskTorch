{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE InstanceSigs #-}

module A1_Syntax.B2_Typological.TENS_Vocab where

import GHC.TypeLits (Nat)
import Torch.Typed.Tensor (Tensor)

-- | Vocabulary for the tensor category TENS.
--   Objects are shape-indexed tensor spaces R^shape.
--   Morphisms are ordinary functions (Sec. 4.1: differentiability only in theta).
class TensVocab a

instance TensVocab (Tensor device dtype shape)

instance (TensVocab a, TensVocab b) => TensVocab (a, b)

instance TensVocab ()
