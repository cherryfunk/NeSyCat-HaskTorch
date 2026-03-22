{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module C_Domain.B_Theory.BinaryTheory where

import A_Categorical.B_Theory.StarTheory (Framework (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import Data.Kind (Type)

-- | Non-Logical Theory Sigma_gamma for the Binary Classification domain.
--
-- Sorts  = {Point, Omega}
-- Fun    = {labelA : Point -> Omega}
-- KlFun  = {classifierA : Theta -> Point -> Mon(Omega)}
--
-- The monad comes from the framework (Mon frmwk).
-- The parameter Theta (= ParamsMLP) is external (from Para), curried in.

-- | BinarySorts: assigns sort names to concrete Haskell types.
class (Framework frmwk) => BinarySorts frmwk where
  type Point frmwk :: Type -- sort: input data point (e.g. R^2)
  type Omega frmwk :: Type -- sort: truth value (e.g. Bool, [0,1])

-- | BinaryFun: plain (deterministic) function symbols.
class (BinarySorts frmwk) => BinaryFun frmwk where
  labelA :: Point frmwk -> Omega frmwk

-- | BinaryKlFun: Kleisli function symbols (morphisms in Kl(Mon frmwk)).
--   The monad comes from the framework -- no separate m parameter.
class (BinaryFun frmwk, Monad (Mon frmwk)) => BinaryKlFun frmwk where
  classifierA :: ParamsMLP -> Point frmwk -> Mon frmwk (Omega frmwk)

-- | Bridge for encoding/decoding between two framework interpretations.
--   The monad for decoding is the source framework's monad (Mon from).
class (BinarySorts from, BinarySorts to) => BinaryBridge from to where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> Mon from (Omega from)
