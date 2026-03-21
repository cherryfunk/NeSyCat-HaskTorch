{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}

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
--     1. BinaryFun DATA -- classifierA + labelA for the DATA category
--     2. BinaryFun TENS -- classifierA + labelA for the TENS category
--     3. BinaryBridge DATA TENS -- encPoint + decOmega
module C_Domain.BA_Interpretation.BinaryReal
  ( module C_Domain.B_Theory.BinaryTheory,
    module C_Domain.BA_Interpretation.BinaryRealMLP,
  )
where

import C_Domain.B_Theory.BinaryTheory (BinaryBridge (..), BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BC_Extension.BinaryDataExtension ()   -- instance BinarySorts DATA
import C_Domain.BC_Extension.BinaryTensExtension ()   -- instance BinarySorts TENS
import A_Categorical.DA_Realization.Dist (Dist (..))
import C_Domain.C_TypeSystem.Data (DATA (..))
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
--  DATA: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun DATA where
  classifierA :: ParamsMLP -> Point DATA -> M DATA (Omega DATA)
  classifierA paramMLP pt =
    let ptTens = encPoint @DATA @TENS pt
        logits = UnsafeMkTensor (hThetaReal paramMLP (Torch.reshape [1, 2] (toDynamic ptTens)))
     in decOmega @DATA @TENS logits

-- ============================================================
--  TENS: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun TENS where
  -- | Label in TENS: returns R logits (True = +logitScale, False = -logitScale).
  --   NOT {0,1} -- those are [0,1] truth values. In R-valued logic,
  --   True = +inf and False = -inf. We use +/-logitScale as a finite proxy.
  labelA :: Point TENS -> Omega TENS
  labelA ptTensor =
    let pt = toDynamic ptTensor
        center = F.mulScalar (Torch.onesLike pt) (0.5 :: Float)
        diff = pt `Torch.sub` center
        dist2 = Torch.sumDim (Torch.Dim (-1)) Torch.KeepDim Torch.Float (diff * diff)
        radiusSq = F.mulScalar (Torch.onesLike dist2) (0.09 :: Float)
        isInside = Torch.lt dist2 radiusSq
        -- Map Bool to R logits: True -> +scale, False -> -scale
        boolFloat = Torch.toType Torch.Float isInside  -- {0, 1}
        scale = F.mulScalar (Torch.onesLike boolFloat) logitScale
        val = boolFloat `Torch.mul` (scale `Torch.add` scale) `Torch.sub` scale
        -- = 2*scale*b - scale = scale*(2b-1) = +scale if b=1, -scale if b=0
     in UnsafeMkTensor val

-- | Finite proxy for +/-inf in R-valued logic.
--   Large enough that sigmoid(logitScale) ~= 1, but finite to avoid NaN.
logitScale :: Float
logitScale = 10.0

-- ============================================================
--  TENS: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun TENS where
  classifierA :: ParamsMLP -> Point TENS -> M TENS (Omega TENS)
  classifierA paramMLP ptTensor = Identity $ do
    let logits = hThetaReal paramMLP (toDynamic ptTensor)
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
     in FiniteSupp [(True, p), (False, 1.0 - p)]
