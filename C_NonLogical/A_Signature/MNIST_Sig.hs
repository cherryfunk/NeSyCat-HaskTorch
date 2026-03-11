{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

{- HLINT ignore "Use camelCase" -}

module C_NonLogical.A_Signature.MNIST_Sig where

import Data.Kind (Type)

-- | Non-Logical Vocabulary Σ for the MNIST Addition domain.
--
-- Sor = {Image, Digit}
-- Fun = {digit : Image → Digit, add : Image² → Digit}
data ImagePairRow = ImagePairRow
  { im1 :: Int,
    im2 :: Int,
    sumLabel :: Int
  }
  deriving (Eq, Show)

-- | Signature, parameterized by the interpreting category (DATA or TENS):
class MNIST_Vocab (cat :: Type -> Type) where
  type Image cat :: Type
  type Digit cat :: Type
  type Omega cat :: Type
  type M cat :: Type -> Type

  -- digit : Image -> Digit
  digit :: Image cat -> (M cat) (Digit cat)

  -- add : Image^2 -> Digit
  add :: (Image cat, Image cat) -> Digit cat

  -- digitPlus : Digit x Digit -> Digit  (addition of digits)
  digitPlus :: Digit cat -> Digit cat -> Digit cat

  -- digitEq : Digit x Digit -> Omega  (equality predicate)
  digitEq :: Digit cat -> Digit cat -> Omega cat

-- | Bridge: encoding/decoding functor between two categories.
--   For every sort S: enc_S maps I_from(S) → I_to(S)
--   dec maps I_to(S) → (M from)(I_from(S))
class (MNIST_Vocab from, MNIST_Vocab to) => MNIST_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encImage :: Image from -> Image to
  encDigit :: Digit from -> Digit to
  decDigit :: Digit to -> (M from) (Digit from)
