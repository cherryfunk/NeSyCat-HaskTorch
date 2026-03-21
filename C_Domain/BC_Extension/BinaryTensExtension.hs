{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}

-- | B_Realization: sort assignment (Point, Omega, M) for TENS category.
module C_Domain.BC_Extension.BinaryTensExtension where

import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.C_TypeSystem.Tens (TENS)
import qualified B_Logical.BA_Interpretation.TensReal as TensLogic
import Data.Functor.Identity (Identity)
import Torch.Typed.Tensor (Tensor)
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))

instance BinarySorts TENS where
  type Point  TENS = Tensor '( 'CPU, 0) 'Float '[2]
  type Omega  TENS = TensLogic.Omega  -- = Tensor '(CPU,0) Float '[1]
  type M      TENS = Identity
