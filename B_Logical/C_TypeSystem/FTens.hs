{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

-- | The logical type system for the geometry paradigm.
--   FTensObj = TensObj + exponentials (function spaces) + monadic types.
--   Mirrors FDataObj for the set/probability paradigm.
module B_Logical.C_TypeSystem.FTens
  ( FTensObj,
  )
where

import C_Domain.C_TypeSystem.Tens (TensObj)

-- | Objects of FTENS: the Cartesian closed, monad-closed extension of TENS.
class FTensObj a

-- | Embed any TensObj into FTensObj.
instance (TensObj a) => FTensObj a

-- | Exponential object (function space).
instance (FTensObj a, FTensObj b) => FTensObj (a -> b)

-- | Monadic object (for Kleisli lifting).
instance (Monad m, FTensObj a) => FTensObj (m a)
