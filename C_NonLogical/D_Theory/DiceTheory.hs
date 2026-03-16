{-# LANGUAGE AllowAmbiguousTypes #-}

module C_NonLogical.A_Signature.Dice_Sig where

-- | Non-Logical Vocabulary for the Dice domain.

-- | Sorts:
type DieResult = Int

-- | Signature:
class Dice_Vocab m where
  -- mFun (Kleisli):
  die :: m DieResult
