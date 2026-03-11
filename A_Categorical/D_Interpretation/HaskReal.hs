{-# LANGUAGE MultiParamTypeClasses #-}
module A_Categorical.D_Interpretation.HaskReal where

import A_Categorical.A_Signature.HaskSig (CatFunS (..), Cat2FunS (..))
import Control.Monad (join)

-- | Hask Interpretation: assigns concrete Haskell functions to the
--   abstract function symbols declared in HaskSig.

instance CatFunS where
  ident unwrap = unwrap

instance Cat2FunS where
  eta = return
  mu  = join
