{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

module B_Interpretation.B_Typological.TENS where

import A_Syntax.B_Logical.TENS_Vocab (TensVocab)
import Numeric.Natural (Natural)
import Torch.Typed.Tensor (Tensor, toDynamic)

-- | Eq for typed Tensors: device-polymorphic.
instance Eq (Tensor device dtype shape) where
  (==) :: Tensor device dtype shape -> Tensor device dtype shape -> Bool
  a == b = toDynamic a == toDynamic b

-- | Objects of TENS: exactly the types declared in TensVocab.
--   Each constructor requires TensVocab a, so only vocab-admitted
--   types can appear as objects.
data TENS a where
  TensorSpace ::
    (TensVocab (Tensor d dt s), Eq (Tensor d dt s)) =>
    TENS (Tensor d dt s) -- R^shape
  TensProd ::
    (TensVocab a, TensVocab b) =>
    TENS a ->
    TENS b ->
    TENS (a, b)
  TensUnit :: TENS () -- terminal object
  TensFin :: Natural -> TENS Natural -- finite set {0,...,n-1}
