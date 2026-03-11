{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | Categorical Signature Σ_α for the Hask category.
--
-- At the α-level, the category is always Hask (implicit).
-- No parameterization by cat needed.
--
--   Sorts:  Obj = Type (objects of Hask are Haskell types)
--   1-cells: endofunctors, bifunctors, constants (listed in HaskVocab)
--   2-cells: natural transformations (η, μ — declared in Cat2FunS)

-- ============================================================
--  Sort symbol: Obj
-- ============================================================

-- | Obj: the sort of objects in Hask.
--   Abstract name; realized as Data.Kind.Type in HaskRlz.
type Obj = Type
