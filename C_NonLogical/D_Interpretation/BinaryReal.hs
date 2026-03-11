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
--   This module only provides:
--     1. BinarySort — GADT witnessing which sorts belong to this interpretation
--     2. BinarySig DATA — classifierA + labelA for the DATA category
--     3. BinarySig TENS — classifierA + labelA for the TENS category
--     4. Binary_Bridge DATA TENS — encPoint + decOmega
module C_NonLogical.D_Interpretation.BinaryReal
  ( BinarySort (..),
    setGlobalBinaryMLP,
    module C_NonLogical.A_Signature.BinarySig,
    module C_NonLogical.D_Interpretation.BinaryRealMLP,
  )
where

import B_Logical.C_Vocabulary.TENS_Vocab ()
import C_NonLogical.A_Signature.BinarySig (Binary_Bridge (..), BinarySig (..), BinarySorts (..))
import C_NonLogical.B_Realization.BinaryDataRlz ()   -- instance BinarySorts DATA
import C_NonLogical.B_Realization.BinaryTensRlz ()   -- instance BinarySorts TENS
import A_Categorical.D_Interpretation.Monads.Dist (Dist (..))
import B_Logical.D_Interpretation.DATA (DATA (..))
import B_Logical.D_Interpretation.TENS (TENS (..))
import qualified B_Logical.D_Interpretation.Boolean as BoolLogic
import B_Logical.D_Interpretation.TensReal hiding (Omega, TENS)
import qualified B_Logical.D_Interpretation.TensReal as TensLogic
import C_NonLogical.D_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
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

-- | Witness that type `a` is a valid sort in the binary classification
--   interpretation of category `cat`.
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
--  DATA: classifierA + labelA
-- ============================================================

instance BinarySig DATA where
  type Params DATA = ()
  classifierA :: Params DATA -> Point DATA -> M DATA (Omega DATA)
  classifierA _params pt = unsafePerformIO $ do
    m <- readIORef globalBinaryMLP
    let ptTens = encPoint @DATA @TENS pt
        logits = UnsafeMkTensor (hThetaReal m (Torch.reshape [1, 2] (toDynamic ptTens)))
    return (decOmega @DATA @TENS logits)

  labelA :: Point DATA -> M DATA (Omega DATA)
  labelA (x1, x2) =
    let dx = x1 - 0.5
        dy = x2 - 0.5
        isInside = dx * dx + dy * dy < 0.09
     in Dist [(True, if isInside then 1.0 else 0.0), (False, if isInside then 0.0 else 1.0)]

-- ============================================================
--  TENS: classifierA + labelA
-- ============================================================

instance BinarySig TENS where
  type Params TENS = Binary_MLP
  classifierA :: Params TENS -> Point TENS -> M TENS (Omega TENS)
  classifierA m ptTensor = Identity $ do
    let logits = hThetaReal m (toDynamic ptTensor)
    UnsafeMkTensor logits

  labelA :: Point TENS -> M TENS (Omega TENS)
  labelA ptTensor =
    let pt = toDynamic ptTensor
        center = F.mulScalar (Torch.onesLike pt) (0.5 :: Float)
        diff = pt `Torch.sub` center
        dist2 = Torch.sumDim (Torch.Dim (-1)) Torch.KeepDim Torch.Float (diff * diff)
        radiusSq = F.mulScalar (Torch.onesLike dist2) (0.09 :: Float)
        isInside = Torch.lt dist2 radiusSq
        val = Torch.toType Torch.Float isInside
     in Identity (UnsafeMkTensor val)

-- ============================================================
--  BRIDGE: DATA <-> TENS encoding/decoding
-- ============================================================

instance Binary_Bridge DATA TENS where
  encPoint :: Point DATA -> Point TENS
  encPoint (x1, x2) = UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor [x1, x2]))

  decOmega :: Omega TENS -> (M DATA) (Omega DATA)
  decOmega probs =
    let val = Torch.asValue (Torch.sigmoid (toDynamic probs)) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in Dist [(True, p), (False, 1.0 - p)]
