{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

-- | MNIST — Bridge: instance MNIST_Bridge DATA TENS
module A2_Interpretation.B4_NonLogical.MNIST_Bridge where

import A1_Syntax.B4_NonLogical.MNIST_Vocab (MNIST_Bridge (..), MNIST_Vocab (..))
import A2_Interpretation.B1_Categorical.Monads.Dist (Dist (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
-- Bring instances into scope:
import A2_Interpretation.B4_NonLogical.MNIST_DATA ()
import A2_Interpretation.B4_NonLogical.MNIST_TENS ()

------------------------------------------------------
-- instance MNIST_Bridge DATA TENS
------------------------------------------------------

instance MNIST_Bridge DATA TENS where
  encImage :: Image DATA -> Image TENS
  encImage path = undefined -- TODO: load PNG, flatten 28x28 → R^784

  encDigit :: Digit DATA -> Digit TENS
  encDigit d = undefined -- TODO: one-hot encoding → R^10

  encNat :: Nat DATA -> Nat TENS
  encNat n = undefined -- TODO: fromIntegral → R^1

  decDigit :: Digit TENS -> (M DATA) (Digit DATA)
  decDigit logits = undefined -- TODO: softmax → Dist Natural
