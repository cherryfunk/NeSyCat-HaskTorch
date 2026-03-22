{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

-- | The logical type system for the set/probability paradigm.
--   FDataObj = DataObj + exponentials (function spaces) + monadic types.
module B_Logical.C_TypeSystem.FData
  ( FDataObj,
  )
where

import C_Domain.C_TypeSystem.Data (DataObj)

-- | Objects of FDATA: the Cartesian closed, monad-closed extension of DATA.
class FDataObj a

-- | Embed any DataObj into FDataObj.
instance (DataObj a) => FDataObj a

-- | Exponential object (function space).
instance (FDataObj a, FDataObj b) => FDataObj (a -> b)

-- | Monadic object (for Kleisli lifting).
instance (Monad m, FDataObj a) => FDataObj (m a)
