{-# LANGUAGE GADTs #-}

module B_Interpretation.B_Typological.FDATA where

import B_Interpretation.B_Typological.DATA (DATA)

-- | The category FDATA (cartesian closed extension of DATA)
-- FDATA = DATA + exponentials (function objects) + monadic objects.
--
-- DATA has finite products (Unit, Prod).
-- FDATA adds:
--   - Exponentials (function spaces a -> b), making it cartesian closed.
--   - Monadic types (m a), for Kleisli interpretation.
data FDATA a where
  -- | Embed any DATA object into FDATA.
  Embed :: DATA a -> FDATA a
  -- | Exponential object (function space).
  Exp :: FDATA a -> FDATA b -> FDATA (a -> b)
  -- | Monadic object (for Kleisli lifting).
  Monadic :: (Monad m) => FDATA a -> FDATA (m a)
