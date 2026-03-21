{-# LANGUAGE TypeFamilies #-}

-- | Sort assignment (Point, Omega) for DATA type system.
--   The monad is a separate choice -- see BinaryKlFun instances.
module C_Domain.BC_Extension.BinaryDataExtension where

import C_Domain.B_Theory.BinaryTheory (BinarySorts (..))
import C_Domain.C_TypeSystem.Data (DATA)
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic

instance BinarySorts DATA where
  type Point  DATA = (Float, Float)  -- R^2 as a Cartesian product
  type Omega  DATA = BoolLogic.Omega  -- = Bool
