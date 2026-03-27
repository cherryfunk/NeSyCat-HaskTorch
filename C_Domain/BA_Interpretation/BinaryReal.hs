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
--     1. BinaryFun MeasU / GeomU -- labelA for each universe
--     2. BinaryKlFun MeasU -- classifierA (Mon = Dist)
--     3. BinaryKlFun GeomU -- classifierA (Mon = Identity)
--     4. BinaryBridge MeasU GeomU -- encPoint + decOmega
module C_Domain.BA_Interpretation.BinaryReal
  ( module C_Domain.B_Theory.BinaryTheory,
    module C_Domain.BA_Interpretation.BinaryRealMLP,
  )
where

import A_Categorical.BA_Interpretation.StarIntp (GeomU, MeasU)
-- instance BinarySorts MeasU
-- instance BinarySorts GeomU
import A_Categorical.DA_Realization.Dist (Dist (..))
import qualified B_Logical.BA_Interpretation.Boolean as BoolLogic
import B_Logical.BA_Interpretation.Tensor hiding (Omega)
import qualified B_Logical.BA_Interpretation.Tensor as TensLogic
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, binarySpecReal, hThetaReal)
import C_Domain.BC_Extension.BinaryDataExtension ()
import C_Domain.BC_Extension.BinaryTensExtension ()
import C_Domain.B_Theory.BinaryTheory (BinaryBridge (..), BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import Data.Functor.Identity (Identity (..))
import Torch (asTensor)
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  MeasU: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun MeasU where
  labelA :: Point MeasU -> Omega MeasU
  labelA (x1, x2) =
    let dx = x1 - 0.5
        dy = x2 - 0.5
     in dx * dx + dy * dy < 0.09

-- ============================================================
--  MeasU: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun MeasU where
  classifierA :: ParamsMLP -> Point MeasU -> Dist (Omega MeasU)
  classifierA paramMLP pt =
    let ptTens = encPoint @MeasU @GeomU pt
        logits =
          UnsafeMkTensor
            (hThetaReal paramMLP (Torch.reshape [1, 2] (toDynamic ptTens)))
     in decOmega @MeasU @GeomU logits

-- ============================================================
--  GeomU: plain function symbols (BinaryFun)
-- ============================================================

instance BinaryFun GeomU where
  -- \| Label in GeomU: returns R logits (True = +logitScale, False = -logitScale).
  labelA :: Point GeomU -> Omega GeomU
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
--  GeomU: Kleisli function symbols (BinaryKlFun)
-- ============================================================

instance BinaryKlFun GeomU where
  classifierA :: ParamsMLP -> Point GeomU -> Identity (Omega GeomU)
  classifierA paramMLP ptTensor = Identity $ do
    let logits = hThetaReal paramMLP (toDynamic ptTensor)
    UnsafeMkTensor logits

-- ============================================================
--  BRIDGE: MeasU <-> GeomU (with Dist monad for decoding)
-- ============================================================

instance BinaryBridge MeasU GeomU where
  encPoint :: Point MeasU -> Point GeomU
  encPoint (x1, x2) =
    UnsafeMkTensor (Torch.toDevice (Device CPU 0) (asTensor [x1, x2]))

  decOmega :: Omega GeomU -> Dist (Omega MeasU)
  decOmega probs =
    let val =
          Torch.asValue (Torch.sigmoid (toDynamic probs)) :: [[Float]]
        p = realToFrac (head (head val)) :: Double
     in FiniteSupp [(True, p), (False, 1.0 - p)]
