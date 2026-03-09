{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module B_Interpretation.D_NonLogical.Binary_Real
  ( setGlobalBinaryMLP,
    module A_Syntax.D_NonLogical.Binary_Vocab,
    module B_Interpretation.D_NonLogical.Binary_MLP_Real,
  )
where

import A_Syntax.B_Typological.TENS_Vocab ()
import A_Syntax.D_NonLogical.Binary_Vocab (Binary_Bridge (..), Binary_Vocab (..))
import C_Semantics.A_Categorical.Monads.Dist (Dist (..))
import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import qualified B_Interpretation.C_Logical.Boolean as BoolLogic
import B_Interpretation.C_Logical.TensReal hiding (Omega, TENS)
import qualified B_Interpretation.C_Logical.TensReal as TensLogic
import B_Interpretation.D_NonLogical.Binary_MLP_Real (Binary_MLP, binarySpecReal, hThetaReal)
import Data.Functor.Identity (Identity (..))
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import System.IO.Unsafe (unsafePerformIO)
import Torch (Randomizable (..), asTensor)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

{-# NOINLINE globalBinaryMLP #-}
globalBinaryMLP :: IORef Binary_MLP
globalBinaryMLP = unsafePerformIO $ do
  m <- sample binarySpecReal
  newIORef m

setGlobalBinaryMLP :: Binary_MLP -> IO ()
setGlobalBinaryMLP = writeIORef globalBinaryMLP

-- ============================================================
--  DATA: Ground truth prediction
-- ============================================================

instance Binary_Vocab DATA where
  type Point DATA = [Float]
  type Omega DATA = BoolLogic.Omega -- = Bool, from the logical vocabulary
  type M DATA = Dist

  type Params DATA = ()

  classifierA :: Params DATA -> Point DATA -> M DATA (Omega DATA)
  classifierA _params pt = unsafePerformIO $ do
    m <- readIORef globalBinaryMLP
    let ptTens = encPoint @DATA @TENS pt
        logits = UnsafeMkTensor (hThetaReal m (Torch.reshape [1, 2] (toDynamic ptTens)))
    return (decOmega @DATA @TENS logits)

  -- \| Ground truth label: a computable predicate
  labelA :: Point DATA -> M DATA (Omega DATA)
  labelA pt =
    let [x1, x2] = pt
        dx = x1 - 0.5
        dy = x2 - 0.5
        isInside = dx * dx + dy * dy < 0.09 -- radius² = 0.3² = 0.09
     in Dist [(True, if isInside then 1.0 else 0.0), (False, if isInside then 0.0 else 1.0)]

-- ============================================================
--  TENS: Tensor logic
-- ============================================================

instance Binary_Vocab TENS where
  type Point TENS = Tensor '( 'CPU, 0) 'Float '[2] -- typed 2D input point
  type Omega TENS = TensLogic.Omega -- = Tensor '(CPU,0) 'Float '[1], from the logical vocabulary
  type M TENS = Identity

  type Params TENS = Binary_MLP

  classifierA :: Params TENS -> Point TENS -> M TENS (Omega TENS)
  classifierA m ptTensor = Identity $ do
    -- Allow dynamic batch sizes: pass directly
    let logits = hThetaReal m (toDynamic ptTensor)
    -- Keep output shape identical to computation graph (e.g. [N, 1])
    UnsafeMkTensor logits

  labelA :: Point TENS -> M TENS (Omega TENS)
  labelA ptTensor =
    let pt = toDynamic ptTensor
        center = F.mulScalar (Torch.onesLike pt) (0.5 :: Float)
        diff = pt `Torch.sub` center
        -- KeepDim ensures shape [N, 1] or [1] for broadcasting against A(x) logits
        dist2 = Torch.sumDim (Torch.Dim (-1)) Torch.KeepDim Torch.Float (diff * diff)
        radiusSq = F.mulScalar (Torch.onesLike dist2) (0.09 :: Float)
        isInside = Torch.lt dist2 radiusSq
        val = Torch.toType Torch.Float isInside
     in Identity (UnsafeMkTensor val)

------------------------------------------------------
-- Global Consts (Prevents FFI Overhead in hot loops)
------------------------------------------------------

-- ============================================================
--  BRIDGE: Encoding/Decoding
-- ============================================================

instance Binary_Bridge DATA TENS where
  encPoint :: Point DATA -> Point TENS
  encPoint pt = UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor pt))

  decOmega :: Omega TENS -> (M DATA) (Omega DATA)
  decOmega probs =
    let val = Torch.asValue (Torch.sigmoid (toDynamic probs)) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in Dist [(True, p), (False, 1.0 - p)]
