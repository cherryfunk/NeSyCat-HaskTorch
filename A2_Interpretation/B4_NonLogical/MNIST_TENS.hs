{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE TypeFamilies #-}

-- | MNIST — interpretation in (TENS, Identity)
module A2_Interpretation.B4_NonLogical.MNIST_TENS where

import A1_Syntax.B4_NonLogical.MNIST_Vocab (MNIST_Vocab (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import Data.Functor.Identity (Identity (..))
import Numeric.Natural (Natural)
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import Torch.Typed.Tensor (Tensor)

------------------------------------------------------
-- instance MNIST_Vocab TENS
------------------------------------------------------

instance MNIST_Vocab TENS where
  type Image TENS = Tensor '( 'CPU, 0) 'Float '[784] -- R^784
  type Digit TENS = Tensor '( 'CPU, 0) 'Float '[10] -- R^10
  type Nat TENS = Tensor '( 'CPU, 0) 'Float '[1] -- R^1
  type M TENS = Identity

  digit :: Image TENS -> M TENS (Digit TENS)
  digit imgTensor = Identity (undefined imgTensor) -- TODO: linear layers

  add :: (Image TENS, Image TENS) -> Nat TENS
  add (x, y) = undefined
