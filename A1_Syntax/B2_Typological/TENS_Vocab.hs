{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE InstanceSigs #-}

module A1_Syntax.B2_Typological.TENS_Vocab where

import GHC.TypeLits (Nat)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Vocabulary for the tensor category TENS.
--   Objects are shape-indexed tensor spaces R^shape.
--   Morphisms are ordinary functions (Sec. 4.1: differentiability only in theta).
class TensVocab a

instance TensVocab (Tensor device dtype shape)

instance (TensVocab a, TensVocab b) => TensVocab (a, b)

instance TensVocab ()

-- | Eq for typed Tensors (delegates to untyped Torch.Tensor Eq)
instance Eq (Tensor '( 'CPU, 0) 'Float s) where
  (==) :: Tensor '(CPU, 0) 'Float s -> Tensor '(CPU, 0) 'Float s -> Bool
  a == b = toDynamic a == toDynamic b

-- | Ord for typed Tensors (needed for Map keys)
instance Ord (Tensor '( 'CPU, 0) 'Float '[784]) where
  compare a b = compare (Torch.asValue (toDynamic a) :: [Float]) (Torch.asValue (toDynamic b) :: [Float])
