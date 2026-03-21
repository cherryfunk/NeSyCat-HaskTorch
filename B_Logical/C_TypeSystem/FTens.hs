{-# LANGUAGE GADTs #-}

-- | The logical type system for the geometry paradigm.
--   FTENS = TENS + exponentials (function spaces) + monadic types.
--   Mirrors FDATA for the set/probability paradigm.
module B_Logical.C_TypeSystem.FTens where

import C_Domain.C_TypeSystem.Tens (TENS)

-- | Objects of FTENS: the Cartesian closed, monad-closed extension of TENS.
data FTENS a where
  -- | Embed any TENS object into FTENS.
  EmbedTens :: TENS a -> FTENS a
  -- | Exponential object (function space).
  ExpTens :: FTENS a -> FTENS b -> FTENS (a -> b)
  -- | Monadic object (for Kleisli lifting).
  MonadicTens :: (Monad m) => FTENS a -> FTENS (m a)
