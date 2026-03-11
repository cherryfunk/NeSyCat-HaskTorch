{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module A_Categorical.D_Interpretation.HaskReal where

import A_Categorical.A_Signature.HaskSig (CatFunS (..), Cat2FunS (..))
import A_Categorical.B_Realization.HaskRlz ()
import Control.Monad (join)
import Data.Functor.Identity (Identity)

-- | Hask Interpretation: assigns concrete Haskell functions to the
--   abstract function symbols declared in HaskSig.

instance CatFunS where
  type Ident = Identity

instance Cat2FunS where
  eta = return
  mu  = join
