{-# LANGUAGE AllowAmbiguousTypes #-}

module A_Syntax.C_NonLogical.Crossing_Vocab where

-- | Non-Logical Vocabulary for the Crossing domain.

-- | Sorts:
type LightColor = String

type Decision = Int

-- | Signature:
class Crossing_Vocab m where
  -- mFun (Kleisli):
  lightDetector :: m LightColor
  drivingDecision :: LightColor -> m Decision
