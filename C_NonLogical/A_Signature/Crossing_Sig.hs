{-# LANGUAGE AllowAmbiguousTypes #-}

module C_NonLogical.A_Signature.Crossing_Sig where

-- | Non-Logical Vocabulary for the Crossing domain.

-- | Sorts:
type LightColor = String

type Decision = Int

-- | Signature:
class Crossing_Vocab m where
  -- mFun (Kleisli):
  lightDetector :: m LightColor
  drivingDecision :: LightColor -> m Decision
