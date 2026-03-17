{-# LANGUAGE TypeFamilies #-}

-- | B_Realization: sort assignment (Point, Omega, M) for DATA category.
module C_NonLogical.E_Extension.BinaryDataExtension where

import C_NonLogical.D_Theory.BinaryTheory (BinarySorts (..))
import A_Categorical.F_Interpretation.Monads.Dist (Dist)
import C_NonLogical.A_Category.Data (DATA)
import qualified B_Logical.F_Interpretation.Boolean as BoolLogic

instance BinarySorts DATA where
  type Point  DATA = (Float, Float)  -- R^2 as a Cartesian product
  type Omega  DATA = BoolLogic.Omega  -- = Bool
  type M      DATA = Dist
  type Params DATA = ()              -- Theta_DATA: no learnable parameters
