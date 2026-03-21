{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}

-- | Binary Classification MLP: A simple architecture h_theta : R^2 -> R^1
module C_Domain.BA_Interpretation.BinaryRealMLP
  ( ParamsMLP (..),
    ParamsMLPSpec (..),
    hThetaReal,
    binarySpecReal,
  )
where

import GHC.Generics
import Torch
  ( Linear,
    LinearSpec (..),
    Parameterized,
    Randomizable (..),
    Tensor,
    linear,
  )
import qualified Torch
import qualified Torch.Functional as F

data ParamsMLPSpec = ParamsMLPSpec deriving (Show, Eq)

-- | Simple MLP Architecture matching the LTNtorch notebook
data ParamsMLP = ParamsMLP
  { fc1 :: Linear,
    fc2 :: Linear,
    fc3 :: Linear
  }
  deriving (Generic, Show, Parameterized)

instance Randomizable ParamsMLPSpec ParamsMLP where
  sample :: ParamsMLPSpec -> IO ParamsMLP
  sample ParamsMLPSpec =
    ParamsMLP
      <$> sample (LinearSpec 2 16)
      <*> sample (LinearSpec 16 16)
      <*> sample (LinearSpec 16 1)

-- | h_theta : [B, 2] -> [B, 1] (logits)
hThetaReal :: ParamsMLP -> Tensor -> Tensor
hThetaReal ParamsMLP {..} input =
  let l1 = F.elu (1.0 :: Float) $ linear fc1 input
      l2 = F.elu (1.0 :: Float) $ linear fc2 l1
      l3 = linear fc3 l2
   in l3

binarySpecReal :: ParamsMLPSpec
binarySpecReal = ParamsMLPSpec
