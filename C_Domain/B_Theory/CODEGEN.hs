{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module C_Domain.B_Theory.CODEGEN where

import A_Categorical.B_Theory.StarTheory (Universe (..))
import Data.Kind (Type)

-- | Binary domain theory (generated)
class (Universe u) => BinarySorts u where
  type ParamsMLP u :: Type
  type Point u :: Type
  type Omega u :: Type

class (BinarySorts u) => BinaryRel u where
  classifierA :: ParamsMLP u -> Point u -> Omega u
  classifierA paramMLP pt = undefined
