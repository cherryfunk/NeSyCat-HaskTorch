{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.CatSig where

import Data.Functor.Identity (Identity)
import Data.Kind (Type)
import Data.Void (Void)

-- ============================================================
-- Categorical Vocabulary kappa (Syntax)
-- ============================================================
--
-- The categorical vocabulary kappa (Def. categorical-vocabulary)
-- consists of purely SYNTACTIC symbols. Their semantic
-- interpretation belongs to D_Interpretation.

-- | CATEGORY SYMBOL: Type
--
--   'Type' (from Data.Kind) is the category symbol C.
--   It is a Haskell kind.
--
--   Its INTERPRETATION is the category Hask, whose:
--     Objects   = evaluation sets (inhabitants) of Haskell types
--     Morphisms = Haskell functions between them

-- | The category symbol C:
type C = Type

class Cat_Sig (a :: k)

-- | Functor symbols (Func):
instance Cat_Sig Identity -- id

instance Cat_Sig (->) -- Hom

instance Cat_Sig Void -- bot = vec0

instance Cat_Sig () -- top = vec1

instance Cat_Sig Either -- sqcup = oplus

instance Cat_Sig (,) -- sqcap = otimes

-- | Monad symbols:
instance Cat_Sig []

instance Cat_Sig Maybe
