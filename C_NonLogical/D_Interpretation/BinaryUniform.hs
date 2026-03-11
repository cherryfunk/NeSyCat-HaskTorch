{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module C_NonLogical.D_Interpretation.BinaryUniform
  ( setGlobalBinaryMLP,
    module C_NonLogical.A_Signature.BinarySig,
    module C_NonLogical.D_Interpretation.BinaryUniformMLP,
  )
where

import B_Logical.C_Vocabulary.TENS_Vocab ()
import C_NonLogical.A_Signature.BinarySig (Binary_Bridge (..), BinaryFuns (..), BinaryKlFuns (..), BinarySorts (..))
import C_NonLogical.B_Realization.BinaryDataRlz ()   -- instance BinarySorts DATA
import C_NonLogical.B_Realization.BinaryTensRlz ()   -- instance BinarySorts TENS
import A_Categorical.D_Interpretation.Monads.Dist (Dist (..))
import C_NonLogical.D_Interpretation.DATA (DATA (..))
import B_Logical.D_Interpretation.TENS (TENS (..))
import qualified B_Logical.D_Interpretation.Boolean as BoolLogic
import B_Logical.D_Interpretation.Tensor hiding (Omega, TENS)
import qualified B_Logical.D_Interpretation.Tensor as TensLogic
import C_NonLogical.D_Interpretation.BinaryUniformMLP (Binary_MLP, binarySpec, hTheta)
import Data.Functor.Identity (Identity (..))
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import System.IO.Unsafe (unsafePerformIO)
import Torch (Randomizable (..), asTensor)
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

{-# NOINLINE globalBinaryMLP #-}
globalBinaryMLP :: IORef Binary_MLP
globalBinaryMLP = unsafePerformIO $ do
  m <- sample binarySpec
  newIORef m

setGlobalBinaryMLP :: Binary_MLP -> IO ()
setGlobalBinaryMLP = writeIORef globalBinaryMLP

-- ============================================================
--  DATA: plain function symbols (BinaryFuns)
-- ============================================================

instance BinaryFuns DATA where
  labelA :: Point DATA -> Omega DATA
  labelA (x1, x2) =
    let dx = x1 - 0.5
        dy = x2 - 0.5
     in dx * dx + dy * dy < 0.09

-- ============================================================
--  DATA: Kleisli function symbols (BinaryKlFuns)
-- ============================================================

instance BinaryKlFuns DATA where
  classifierA :: Params DATA -> Point DATA -> M DATA (Omega DATA)
  classifierA _params pt = unsafePerformIO $ do
    m <- readIORef globalBinaryMLP
    let ptTens = encPoint @DATA @TENS pt
        logits = UnsafeMkTensor (hTheta m (Torch.reshape [1, 2] (toDynamic ptTens)))
    return (decOmega @DATA @TENS logits)

-- ============================================================
--  TENS: plain function symbols (BinaryFuns)
-- ============================================================

instance BinaryFuns TENS where
  labelA :: Point TENS -> Omega TENS
  labelA ptTensor =
    let pt = toDynamic ptTensor
        center = F.mulScalar (Torch.onesLike pt) 0.5
        diff = pt `Torch.sub` center
        dist2 = Torch.sumDim (Torch.Dim (-1)) Torch.KeepDim Torch.Float (diff * diff)
        radiusSq = F.mulScalar (Torch.onesLike dist2) 0.09
        isInside = Torch.lt dist2 radiusSq
        val = Torch.toType Torch.Float isInside
     in UnsafeMkTensor val

-- ============================================================
--  TENS: Kleisli function symbols (BinaryKlFuns)
-- ============================================================

instance BinaryKlFuns TENS where
  classifierA :: Params TENS -> Point TENS -> M TENS (Omega TENS)
  classifierA m ptTensor = Identity $ do
    let logits = hTheta m (toDynamic ptTensor)
    UnsafeMkTensor logits

-- ============================================================
--  BRIDGE: DATA <-> TENS encoding/decoding
-- ============================================================

instance Binary_Bridge DATA TENS where
  encPoint :: Point DATA -> Point TENS
  encPoint (x1, x2) = UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor [x1, x2]))

  decOmega :: Omega TENS -> (M DATA) (Omega DATA)
  decOmega probs =
    let val = Torch.asValue (toDynamic probs) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in Dist [(True, p), (False, 1.0 - p)]
