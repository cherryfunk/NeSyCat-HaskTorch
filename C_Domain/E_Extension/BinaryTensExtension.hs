{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}

-- | B_Realization: sort assignment (Point, Omega, M, Params) for TENS category.
module C_Domain.E_Extension.BinaryTensExtension where

import C_Domain.D_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP)
import B_Logical.A_Category.Tens (TENS)
import qualified B_Logical.F_Interpretation.TensReal as TensLogic
import Data.Functor.Identity (Identity)
import Torch.Typed.Tensor (Tensor)
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))

instance BinarySorts TENS where
  type Point  TENS = Tensor '( 'CPU, 0) 'Float '[2]
  type Omega  TENS = TensLogic.Omega  -- = Tensor '(CPU,0) Float '[1]
  type M      TENS = Identity
  type ParamsDomain TENS = Binary_MLP -- Θ_TENS: neural network weights
