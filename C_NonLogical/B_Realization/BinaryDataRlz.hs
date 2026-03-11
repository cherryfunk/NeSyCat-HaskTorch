{-# LANGUAGE TypeFamilies #-}

-- | B_Realization: sort assignment (Point, Omega, M) for DATA category.
module C_NonLogical.B_Realization.BinaryDataRlz where

import C_NonLogical.A_Signature.BinarySig (BinarySorts (..))
import A_Categorical.D_Interpretation.Monads.Dist (Dist)
import C_NonLogical.D_Interpretation.DATA (DATA)
import qualified B_Logical.D_Interpretation.Boolean as BoolLogic

instance BinarySorts DATA where
  type Point DATA = (Float, Float)  -- ℝ² as a Cartesian product
  type Omega DATA = BoolLogic.Omega  -- = Bool
  type M     DATA = Dist
