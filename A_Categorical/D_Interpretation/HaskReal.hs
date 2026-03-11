{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module A_Categorical.D_Interpretation.HaskReal where

import A_Categorical.A_Signature.HaskSig (CatFunS (..), Cat2FunS (..))
import A_Categorical.B_Realization.HaskRlz ()
import Control.Monad (join)
import Data.Functor.Identity (Identity)
import qualified A_Categorical.D_Interpretation.Monads.Dist as M
import qualified A_Categorical.D_Interpretation.Monads.Giry as M

-- | Hask Interpretation: assigns concrete Haskell functions to the
--   abstract function symbols declared in HaskSig.

instance CatFunS where
  type Ident = Identity
  type Dist = M.Dist
  type Giry = M.Giry

instance Cat2FunS where
  eta = return
  mu  = join
