-- | The TENS type system (geometry paradigm).
--   TensObj marks which types are objects of the geometry domain category.
module C_Domain.C_TypeSystem.Tens
  ( TensObj (..),
  )
where

import qualified Torch

-- | Type membership in the TENS type system.
class TensObj a

instance TensObj Torch.Tensor
instance (TensObj a, TensObj b) => TensObj (a, b)
instance TensObj ()
