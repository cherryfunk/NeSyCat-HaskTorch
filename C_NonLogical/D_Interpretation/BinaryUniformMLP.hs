{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}

-- | Binary Classification MLP: A simple architecture h_theta : R^2 -> R^1
module C_NonLogical.D_Interpretation.BinaryUniformMLP
  ( Binary_MLP (..),
    Binary_MLPSpec (..),
    hTheta,
    binarySpec,
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

data Binary_MLPSpec = Binary_MLPSpec deriving (Show, Eq)

-- | Simple MLP Architecture matching the LTNtorch notebook
data Binary_MLP = Binary_MLP
  { fc1 :: Linear,
    fc2 :: Linear,
    fc3 :: Linear
  }
  deriving (Generic, Show, Parameterized)

instance Randomizable Binary_MLPSpec Binary_MLP where
  sample :: Binary_MLPSpec -> IO Binary_MLP
  sample Binary_MLPSpec =
    Binary_MLP
      <$> sample (LinearSpec 2 16)
      <*> sample (LinearSpec 16 16)
      <*> sample (LinearSpec 16 1)

-- | h_theta : [B, 2] -> [B, 1] (probabilities)
hTheta :: Binary_MLP -> Tensor -> Tensor
hTheta Binary_MLP {..} input =
  let l1 = F.elu (1.0 :: Float) $ linear fc1 input
      l2 = F.elu (1.0 :: Float) $ linear fc2 l1
      l3 = Torch.sigmoid $ linear fc3 l2
   in l3

binarySpec :: Binary_MLPSpec
binarySpec = Binary_MLPSpec
