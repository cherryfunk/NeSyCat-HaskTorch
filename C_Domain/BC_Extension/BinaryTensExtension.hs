{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}

-- | Sort assignment (Point, Omega) for the geometry framework.
module C_Domain.BC_Extension.BinaryTensExtension where

import A_Categorical.BA_Interpretation.StarIntp (FrmwkGeom)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import qualified B_Logical.BA_Interpretation.Tensor as TensLogic
import Torch.Typed.Tensor (Tensor)
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))

instance BinarySorts FrmwkGeom where
  type Point  FrmwkGeom = Tensor '( 'CPU, 0) 'Float '[2]
  type Omega  FrmwkGeom = TensLogic.Omega  -- = Tensor '(CPU,0) Float '[1]
