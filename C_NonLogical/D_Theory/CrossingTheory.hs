{-# LANGUAGE AllowAmbiguousTypes #-}

module C_NonLogical.D_Theory.CrossingTheory where

-- | Non-Logical Vocabulary for the Crossing domain.

-- | Sorts:
type LightColor = String

type Decision = Int

-- | Signature:
class CrossingTheory m where
  -- mFun (Kleisli):
  lightDetector :: m LightColor
  drivingDecision :: LightColor -> m Decision
