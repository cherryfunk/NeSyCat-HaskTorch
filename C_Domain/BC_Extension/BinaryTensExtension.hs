{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}

-- | Sort assignment (Point, Omega) for TENS type system.
--   The monad is a separate choice -- see BinaryKlFun instances.
module C_Domain.BC_Extension.BinaryTensExtension where

import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.C_TypeSystem.Tens (TENS)
import qualified B_Logical.BA_Interpretation.Tensor as TensLogic
import Torch.Typed.Tensor (Tensor)
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))

instance BinarySorts TENS where
  type Point  TENS = Tensor '( 'CPU, 0) 'Float '[2]
  type Omega  TENS = TensLogic.Omega  -- = Tensor '(CPU,0) Float '[1]
