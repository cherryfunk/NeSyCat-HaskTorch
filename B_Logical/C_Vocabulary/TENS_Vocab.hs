{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE UndecidableInstances #-}

module B_Logical.C_Vocabulary.TENS_Vocab where

import B_Logical.D_Interpretation.TENS (TENS (..))
import Numeric.Natural (Natural)
import qualified Torch.Tensor
import Torch.Typed.Tensor (Tensor)

-- | Vocabulary for the tensor category TENS.
--   Every sort must provide its canonical TENS witness.
--   This locks TensVocab and TENS together:
--   you cannot add a sort without a TENS constructor.
class TensVocab a where
  tensWitness :: TENS a

instance TensVocab (Tensor d dt s) where
  tensWitness :: TENS (Tensor d dt s)
  tensWitness = TensorSpace

instance TensVocab Natural where
  tensWitness :: TENS Natural
  tensWitness = TensFin

instance (TensVocab a, TensVocab b) => TensVocab (a, b) where
  tensWitness :: (TensVocab a, TensVocab b) => TENS (a, b)
  tensWitness = TensProd tensWitness tensWitness

instance TensVocab () where
  tensWitness :: TENS ()
  tensWitness = TensUnit
