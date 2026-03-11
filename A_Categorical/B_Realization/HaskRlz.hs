module A_Categorical.B_Realization.HaskRlz where

import A_Categorical.A_Signature.HaskSig (Obj)

-- | Hask Realization
--
--   The abstract sort symbol Obj is realized as Data.Kind.Type.
--   This is already the case by definition (Obj = Type in HaskSig),
--   so this module simply re-exports and documents the fact:
--
--   Obj = Type   ⇒   objects of Hask are Haskell types of kind Type.
--
--   (Unlike BinaryDataRlz/BinaryTensRlz which assign different
--   concrete types per category, here there is only one realization.)
