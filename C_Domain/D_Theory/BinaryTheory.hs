{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}


module C_Domain.D_Theory.BinaryTheory where

import Data.Kind (Type)

-- | Non-Logical Theory Sigma_gamma for the Binary Classification domain.
--
-- Sorts  = {Point, Omega}
-- Fun    = {labelA : Point -> Omega}            -- plain (interpreted in C)
-- KlFun  = {classifierA : Point -> Omega}       -- Kleisli (interpreted in Kl(M))
--
-- Additionally, Theta (parameter space) parameterizes the interpretation I_theta

-- | BinarySorts: assigns abstract sort names to concrete Haskell types.
--   Instances live in E_Extension/.
class BinarySorts (cat :: Type -> Type) where
  type Point cat :: Type         -- sort: input data point (e.g. R^2)
  type Omega cat :: Type         -- sort: truth value (e.g. Bool, [0,1])
  type M cat :: Type -> Type     -- monad M defining the Kleisli category Kl(M)
  type ParamsDomain cat :: Type   -- Theta: parameter space of I_theta

-- | BinaryFun: plain (deterministic) function symbols.
--   Interpreted as morphisms in C (not Kl(M)).
--   Instances live in F_Interpretation/.
class (BinarySorts cat) => BinaryFun (cat :: Type -> Type) where
  labelA :: Point cat -> Omega cat

-- | BinaryKlFun: Kleisli function symbols.
--   Interpreted as morphisms in Kl(M), i.e. A -> M(B) in Haskell.
--   Instances live in F_Interpretation/.
class (BinaryFun cat) => BinaryKlFun (cat :: Type -> Type) where
  classifierA :: ParamsDomain cat -> Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between two category interpretations.
--   Only requires BinarySorts: encPoint/decOmega use only sort assignments.
class (BinarySorts from, BinarySorts to) => BinaryBridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
