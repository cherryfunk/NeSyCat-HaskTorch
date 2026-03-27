{-# LANGUAGE TypeFamilies #-}

-- | Sort assignment (Point, Omega) for the geometry universe.
module C_Domain.BC_Extension.BinaryTensExtension where

import A_Categorical.BA_Interpretation.StarIntp (GeomU)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import qualified B_Logical.BA_Interpretation.Tensor as TensLogic
import qualified Torch

instance BinarySorts GeomU where
  type Point  GeomU = Torch.Tensor  -- shape: [2], dtype: Float
  type Omega  GeomU = TensLogic.Omega  -- = Torch.Tensor
