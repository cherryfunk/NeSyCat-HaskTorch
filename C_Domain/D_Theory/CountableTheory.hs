{-# LANGUAGE AllowAmbiguousTypes #-}

module C_Domain.D_Theory.CountableTheory where

-- | Non-Logical Vocabulary for the Countable sets domain.

-- | Signature:
class CountableTheory m where
  -- mFun (Kleisli):
  drawInt :: m Int
  drawStr :: m String
  drawLazy :: m Int
  drawHeavy :: m Int
