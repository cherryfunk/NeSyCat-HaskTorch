{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}

-- | B_Realization: sort assignment (Point, Omega, M, Params) for TENS category.
module C_NonLogical.B_Realization.BinaryTensRlz where

import C_NonLogical.A_Signature.BinarySig (BinarySorts (..))
import C_NonLogical.D_Interpretation.BinaryRealMLP (Binary_MLP)
import B_Logical.D_Interpretation.TENS (TENS)
import qualified B_Logical.D_Interpretation.TensReal as TensLogic
import Data.Functor.Identity (Identity)
import Torch.Typed.Tensor (Tensor)
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))

instance BinarySorts TENS where
  type Point  TENS = Tensor '( 'CPU, 0) 'Float '[2]
  type Omega  TENS = TensLogic.Omega  -- = Tensor '(CPU,0) Float '[1]
  type M      TENS = Identity
  type Params TENS = Binary_MLP      -- Θ_TENS: neural network weights
