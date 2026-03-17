{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | D_Interpretation: function implementations for Binary Classification.
--
--   Sort assignments are in B_Realization (BinaryDataRlz, BinaryTensRlz).
--   This module provides:
--     1. BinarySort — GADT sort descriptor (carries sort membership at the term level)
--     2. BinaryFun DATA — classifierA + labelA for the DATA category
--     3. BinaryFun TENS — classifierA + labelA for the TENS category
--     4. BinaryBridge DATA TENS — encPoint + decOmega
module C_Domain.F_Interpretation.BinaryReal
  ( BinarySort (..),
    setGlobalBinaryMLP,
    module C_Domain.D_Theory.BinaryTheory,
    module C_Domain.F_Interpretation.BinaryRealMLP,
  )
where

import B_Logical.B_Vocabulary.TensVocab ()
import C_Domain.D_Theory.BinaryTheory (BinaryBridge (..), BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.E_Extension.BinaryDataExtension ()   -- instance BinarySorts DATA
import C_Domain.E_Extension.BinaryTensExtension ()   -- instance BinarySorts TENS
import A_Categorical.F_Interpretation.Monads.Dist (Dist (..))
import C_Domain.A_Category.Data (DATA (..))
import B_Logical.A_Category.Tens (TENS (..))
import qualified B_Logical.F_Interpretation.Boolean as BoolLogic
import B_Logical.F_Interpretation.TensReal hiding (Omega, TENS)
import qualified B_Logical.F_Interpretation.TensReal as TensLogic
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
import Data.Functor.Identity (Identity (..))
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Data.Kind (Type)
import System.IO.Unsafe (unsafePerformIO)
import Torch (Randomizable (..), asTensor)
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  BinarySort: GADT sort witness for this interpretation
--  Analogous to TENS a witnessing valid tensor sorts.
-- ============================================================

-- | GADT sort descriptor for the BinaryReal interpretation.
--   Each constructor carries the sort membership to the term level,
--   analogous to how TENS a stores which type a is a tensor sort.
data BinarySort (cat :: Type -> Type) a where
  DataPoint :: BinarySort DATA (Point DATA)  -- = (Float, Float) = ℝ²
  DataOmega :: BinarySort DATA (Omega DATA)  -- = Bool
  TensPoint :: BinarySort TENS (Point TENS)  -- = Tensor '(CPU,0) Float '[2]
  TensOmega :: BinarySort TENS (Omega TENS)  -- = Tensor '(CPU,0) Float '[1]

-- ============================================================
--  Global MLP state
-- ============================================================

{-# NOINLINE globalBinaryMLP #-}
globalBinaryMLP :: IORef Binary_MLP
globalBinaryMLP = unsafePerformIO $ do
  m <- sample binarySpecReal
  newIORef m

setGlobalBinaryMLP :: Binary_MLP -> IO ()
setGlobalBinaryMLP = writeIORef globalBinaryMLP

-- ============================================================
--  DATA: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun DATA where
  labelA :: Point DATA -> Omega DATA
  labelA (x1, x2) =
    let dx = x1 - 0.5
        dy = x2 - 0.5
     in dx * dx + dy * dy < 0.09

-- ============================================================
--  DATA: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun DATA where
  classifierA :: Params DATA -> Point DATA -> M DATA (Omega DATA)
  classifierA _params pt = unsafePerformIO $ do
    m <- readIORef globalBinaryMLP
    let ptTens = encPoint @DATA @TENS pt
        logits = UnsafeMkTensor (hThetaReal m (Torch.reshape [1, 2] (toDynamic ptTens)))
    return (decOmega @DATA @TENS logits)

-- ============================================================
--  TENS: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun TENS where
  labelA :: Point TENS -> Omega TENS
  labelA ptTensor =
    let pt = toDynamic ptTensor
        center = F.mulScalar (Torch.onesLike pt) (0.5 :: Float)
        diff = pt `Torch.sub` center
        dist2 = Torch.sumDim (Torch.Dim (-1)) Torch.KeepDim Torch.Float (diff * diff)
        radiusSq = F.mulScalar (Torch.onesLike dist2) (0.09 :: Float)
        isInside = Torch.lt dist2 radiusSq
        val = Torch.toType Torch.Float isInside
     in UnsafeMkTensor val

-- ============================================================
--  TENS: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun TENS where
  classifierA :: Params TENS -> Point TENS -> M TENS (Omega TENS)
  classifierA m ptTensor = Identity $ do
    let logits = hThetaReal m (toDynamic ptTensor)
    UnsafeMkTensor logits

-- ============================================================
--  BRIDGE: DATA <-> TENS encoding/decoding
-- ============================================================

instance BinaryBridge DATA TENS where
  encPoint :: Point DATA -> Point TENS
  encPoint (x1, x2) = UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor [x1, x2]))

  decOmega :: Omega TENS -> (M DATA) (Omega DATA)
  decOmega probs =
    let val = Torch.asValue (Torch.sigmoid (toDynamic probs)) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in Dist [(True, p), (False, 1.0 - p)]
