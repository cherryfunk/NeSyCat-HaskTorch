{-# LANGUAGE TypeFamilies #-}

-- | Sort assignment (Point, Omega) for the measure theory universe.
module C_Domain.BC_Extension.BinaryDataExtension where

import A_Categorical.BA_Interpretation.StarIntp (MeasU)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic

instance BinarySorts MeasU where
  type Point  MeasU = (Float, Float)  -- R^2 as a Cartesian product
  type Omega  MeasU = BoolLogic.Omega  -- = Bool
