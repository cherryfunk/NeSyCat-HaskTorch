{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}

-- | MNIST MLP: the neural network h_theta : R^784 -> R^10
module A2_Interpretation.B4_NonLogical.MNIST_MLP
  ( MLP (..),
    MLPSpec (..),
    hTheta,
    mnistSpec,
    currentModel,
  )
where

import GHC.Generics
import System.IO.Unsafe (unsafePerformIO)
import Torch
  ( Linear,
    LinearSpec (..),
    Parameterized,
    Randomizable (..),
    linear,
    relu,
  )
import qualified Torch

data MLPSpec = MLPSpec
  { inputFeatures :: Int,
    hiddenFeatures :: Int,
    outputFeatures :: Int
  }
  deriving (Show, Eq)

data MLP = MLP
  { l0 :: Linear,
    l1 :: Linear
  }
  deriving (Generic, Show, Parameterized)

instance Randomizable MLPSpec MLP where
  sample :: MLPSpec -> IO MLP
  sample MLPSpec {..} =
    MLP
      <$> sample (LinearSpec inputFeatures hiddenFeatures)
      <*> sample (LinearSpec hiddenFeatures outputFeatures)

-- | h_theta : R^784 -> R^10 (logits, pre-softmax)
hTheta :: MLP -> Torch.Tensor -> Torch.Tensor
hTheta MLP {..} input =
  linear l1
    . relu
    . linear l0
    $ input

-- | Default spec: 784 -> 256 -> 10
mnistSpec :: MLPSpec
mnistSpec = MLPSpec 784 256 10

{-# NOINLINE currentModel #-}
currentModel :: MLP
currentModel = unsafePerformIO (sample mnistSpec)
