{-# LANGUAGE TypeFamilies #-}

-- | Sort assignment (Point, Omega) for the measure theory framework.
module C_Domain.BC_Extension.BinaryDataExtension where

import A_Categorical.BA_Interpretation.StarIntp (FrmwkMeas)
import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic

instance BinarySorts FrmwkMeas where
  type Point  FrmwkMeas = (Float, Float)  -- R^2 as a Cartesian product
  type Omega  FrmwkMeas = BoolLogic.Omega  -- = Bool
