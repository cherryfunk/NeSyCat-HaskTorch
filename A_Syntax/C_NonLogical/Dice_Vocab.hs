{-# LANGUAGE AllowAmbiguousTypes #-}

module A_Syntax.C_NonLogical.Dice_Vocab where

-- | Non-Logical Vocabulary for the Dice domain.

-- | Sorts:
type DieResult = Int

-- | Signature:
class Dice_Vocab m where
  -- mFun (Kleisli):
  die :: m DieResult
