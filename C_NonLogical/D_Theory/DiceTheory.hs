{-# LANGUAGE AllowAmbiguousTypes #-}

module C_NonLogical.D_Theory.DiceTheory where

-- | Non-Logical Vocabulary for the Dice domain.

-- | Sorts:
type DieResult = Int

-- | Signature:
class DiceTheory m where
  -- mFun (Kleisli):
  die :: m DieResult
