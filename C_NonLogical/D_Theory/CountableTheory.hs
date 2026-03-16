{-# LANGUAGE AllowAmbiguousTypes #-}

module C_NonLogical.A_Signature.Countable_Sig where

-- | Non-Logical Vocabulary for the Countable sets domain.

-- | Signature:
class Countable_Vocab m where
  -- mFun (Kleisli):
  drawInt :: m Int
  drawStr :: m String
  drawLazy :: m Int
  drawHeavy :: m Int
