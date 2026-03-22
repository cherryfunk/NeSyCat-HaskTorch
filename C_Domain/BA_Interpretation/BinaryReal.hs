{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Function implementations for Binary Classification.
--
--   This module provides:
--     1. BinaryFun FrmwkMeas / FrmwkGeom -- labelA for each framework
--     2. BinaryKlFun FrmwkMeas -- classifierA (Mon = Dist)
--     3. BinaryKlFun FrmwkGeom -- classifierA (Mon = Identity)
--     4. BinaryBridge FrmwkMeas FrmwkGeom -- encPoint + decOmega
module C_Domain.BA_Interpretation.BinaryReal
  ( module C_Domain.B_Theory.BinaryTheory,
    module C_Domain.BA_Interpretation.BinaryRealMLP,
  )
where

import A_Categorical.BA_Interpretation.StarIntp (FrmwkGeom, FrmwkMeas)
import C_Domain.B_Theory.BinaryTheory (BinaryBridge (..), BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BC_Extension.BinaryDataExtension ()   -- instance BinarySorts FrmwkMeas
import C_Domain.BC_Extension.BinaryTensExtension ()   -- instance BinarySorts FrmwkGeom
import A_Categorical.DA_Realization.Dist (Dist (..))
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic
import B_Logical.BA_Interpretation.Tensor hiding (Omega)
import qualified B_Logical.BA_Interpretation.Tensor as TensLogic
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, binarySpecReal, hThetaReal)
import Data.Functor.Identity (Identity (..))
import Torch (asTensor)
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  FrmwkMeas: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun FrmwkMeas where
  labelA :: Point FrmwkMeas -> Omega FrmwkMeas
  labelA (x1, x2) =
    let dx = x1 - 0.5
        dy = x2 - 0.5
     in dx * dx + dy * dy < 0.09

-- ============================================================
--  FrmwkMeas: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun FrmwkMeas where
  classifierA :: ParamsMLP -> Point FrmwkMeas -> Dist (Omega FrmwkMeas)
  classifierA paramMLP pt =
    let ptTens = encPoint @FrmwkMeas @FrmwkGeom pt
        logits = UnsafeMkTensor (hThetaReal paramMLP (Torch.reshape [1, 2] (toDynamic ptTens)))
     in decOmega @FrmwkMeas @FrmwkGeom logits

-- ============================================================
--  FrmwkGeom: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun FrmwkGeom where
  -- | Label in FrmwkGeom: returns R logits (True = +logitScale, False = -logitScale).
  labelA :: Point FrmwkGeom -> Omega FrmwkGeom
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
--  FrmwkGeom: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun FrmwkGeom where
  classifierA :: ParamsMLP -> Point FrmwkGeom -> Identity (Omega FrmwkGeom)
  classifierA paramMLP ptTensor = Identity $ do
    let logits = hThetaReal paramMLP (toDynamic ptTensor)
    UnsafeMkTensor logits

-- ============================================================
--  BRIDGE: FrmwkMeas <-> FrmwkGeom (with Dist monad for decoding)
-- ============================================================

instance BinaryBridge FrmwkMeas FrmwkGeom where
  encPoint :: Point FrmwkMeas -> Point FrmwkGeom
  encPoint (x1, x2) = UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor [x1, x2]))

  decOmega :: Omega FrmwkGeom -> Dist (Omega FrmwkMeas)
  decOmega probs =
    let val = Torch.asValue (Torch.sigmoid (toDynamic probs)) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in FiniteSupp [(True, p), (False, 1.0 - p)]
