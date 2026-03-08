{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

{- HLINT ignore "Use camelCase" -}

module A1_Syntax.B4_NonLogical.MNIST_Vocab where

import Data.Kind (Type)
import Numeric.Natural (Natural)

-- | Non-Logical Vocabulary Σ for the MNIST Addition domain.
--
-- Sor = {Image, Digit, Natural}
-- Fun = {digit : Image → Digit, add : Image² → Natural}

-- | Data schema:
data ImagePairRow = ImagePairRow
  { im1 :: String,
    im2 :: String,
    sumLabel :: Natural
  }

-- | Signature, parameterized by the interpreting category (DATA or TENS):
class MNIST_Vocab (cat :: Type -> Type) where
  type Image cat :: Type
  type Digit cat :: Type
  type Nat cat :: Type
  type M cat :: Type -> Type

  -- digit : Image → Digit
  digit :: Image cat -> (M cat) (Digit cat)

  -- add : Image² → Natural
  add :: (Image cat, Image cat) -> Nat cat

-- | Bridge: encoding/decoding functor between two categories.
--   For every sort S: enc_S maps I_from(S) → I_to(S)
--   dec maps I_to(S) → (M from)(I_from(S))
class (MNIST_Vocab from, MNIST_Vocab to) => MNIST_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encImage :: Image from -> Image to
  encDigit :: Digit from -> Digit to
  encNat :: Nat from -> Nat to
  decDigit :: Digit to -> (M from) (Digit from)
