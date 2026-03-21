{-# LANGUAGE TypeFamilies #-}

-- | B_Realization: sort assignment (Point, Omega, M) for DATA category.
module C_Domain.BC_Extension.BinaryDataExtension where

import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import A_Categorical.DA_Realization.Dist (Dist)
import C_Domain.A_Category.Data (DATA)
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic

instance BinarySorts DATA where
  type Point  DATA = (Float, Float)  -- R^2 as a Cartesian product
  type Omega  DATA = BoolLogic.Omega  -- = Bool
  type M      DATA = Dist
  type ParamsDomain DATA = ()        -- Theta_DATA: no learnable parameters
