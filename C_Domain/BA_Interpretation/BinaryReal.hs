{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Function implementations for Binary Classification.
--
--   This module provides:
--     1. BinaryFun DATA / TENS -- labelA for each type system
--     2. BinaryKlFun DATA Dist -- classifierA for DATA + Dist
--     3. BinaryKlFun TENS Identity -- classifierA for TENS + Identity
--     4. BinaryBridge DATA TENS Dist -- encPoint + decOmega
module C_Domain.BA_Interpretation.BinaryReal
  ( module C_Domain.B_Theory.BinaryTheory,
    module C_Domain.BA_Interpretation.BinaryRealMLP,
  )
where

import C_Domain.B_Theory.BinaryTheory (BinaryBridge (..), BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BC_Extension.BinaryDataExtension ()   -- instance BinarySorts DATA
import C_Domain.BC_Extension.BinaryTensExtension ()   -- instance BinarySorts TENS
import A_Categorical.DA_Realization.Dist (Dist (..))
import C_Domain.C_TypeSystem.Data (DATA)
import C_Domain.C_TypeSystem.Tens (TENS (..))
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic
import B_Logical.BA_Interpretation.TensReal hiding (Omega, TENS)
import qualified B_Logical.BA_Interpretation.TensReal as TensLogic
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, binarySpecReal, hThetaReal)
import Data.Functor.Identity (Identity (..))
import Torch (asTensor)
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

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
--  DATA + Dist: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun DATA Dist where
  classifierA :: ParamsMLP -> Point DATA -> Dist (Omega DATA)
  classifierA paramMLP pt =
    let ptTens = encPoint @DATA @TENS @Dist pt
        logits = UnsafeMkTensor (hThetaReal paramMLP (Torch.reshape [1, 2] (toDynamic ptTens)))
     in decOmega @DATA @TENS @Dist logits

-- ============================================================
--  TENS: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun TENS where
  -- | Label in TENS: returns R logits (True = +logitScale, False = -logitScale).
  labelA :: Point TENS -> Omega TENS
  labelA ptTensor =
    let pt = toDynamic ptTensor
        center = F.mulScalar (Torch.onesLike pt) (0.5 :: Float)
        diff = pt `Torch.sub` center
        dist2 = Torch.sumDim (Torch.Dim (-1)) Torch.KeepDim Torch.Float (diff * diff)
        radiusSq = F.mulScalar (Torch.onesLike dist2) (0.09 :: Float)
        isInside = Torch.lt dist2 radiusSq
        boolFloat = Torch.toType Torch.Float isInside
        scale = F.mulScalar (Torch.onesLike boolFloat) logitScale
        val = boolFloat `Torch.mul` (scale `Torch.add` scale) `Torch.sub` scale
     in UnsafeMkTensor val

logitScale :: Float
logitScale = 10.0

-- ============================================================
--  TENS + Identity: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun TENS Identity where
  classifierA :: ParamsMLP -> Point TENS -> Identity (Omega TENS)
  classifierA paramMLP ptTensor = Identity $ do
    let logits = hThetaReal paramMLP (toDynamic ptTensor)
    UnsafeMkTensor logits

-- ============================================================
--  BRIDGE: DATA <-> TENS (with Dist monad for decoding)
-- ============================================================

instance BinaryBridge DATA TENS Dist where
  encPoint :: Point DATA -> Point TENS
  encPoint (x1, x2) = UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor [x1, x2]))

  decOmega :: Omega TENS -> Dist (Omega DATA)
  decOmega probs =
    let val = Torch.asValue (Torch.sigmoid (toDynamic probs)) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in FiniteSupp [(True, p), (False, 1.0 - p)]
