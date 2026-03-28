{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module B_Logical.B_Theory.A2MonBLatTheory (
    A2MonBLatTheory (..),
    Guard,
)
where

import A_Categorical.B_Theory.StarTheory (Universe (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import Data.Kind (Type)

-- | Guard: the subset that a guarded quantifier ranges over.
type family Guard u a :: Type

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
class
    (TwoMonBLatTheory u tau, Universe u, Monad (M u)) =>
    A2MonBLatTheory a u tau
    where
    bigWedge :: ParamsLogic tau -> Guard u a -> (a -> M u tau) -> M u tau
    bigVee :: ParamsLogic tau -> Guard u a -> (a -> M u tau) -> M u tau
    bigOplus :: Guard u a -> (a -> M u tau) -> M u tau
    bigOtimes :: Guard u a -> (a -> M u tau) -> M u tau
