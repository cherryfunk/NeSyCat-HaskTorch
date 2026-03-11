{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}

-- | MNIST CNN: A LeNet-5 style architecture h_theta : R^(1x28x28) -> R^10
module C_NonLogical.D_Interpretation.MNIST_MLP
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
    Tensor,
    linear,
    relu,
    toDependent
  )
import Torch.Device (Device (..), DeviceType (..))
import Torch.Tensor (toDevice)
import qualified Torch
import qualified Torch.Functional as F
import Torch.NN (Conv2d (..), Conv2dSpec (..))
import qualified Torch.NN

data MLPSpec = MLPSpec deriving (Show, Eq)

-- | LeNet-5 Architecture definition
data MLP = MLP
  { conv1 :: Conv2d,
    conv2 :: Conv2d,
    fc1 :: Linear,
    fc2 :: Linear,
    fc3 :: Linear
  }
  deriving (Generic, Show, Parameterized)

instance Randomizable MLPSpec MLP where
  sample :: MLPSpec -> IO MLP
  sample MLPSpec =
    MLP
      <$> sample (Conv2dSpec 1 6 5 5)
      <*> sample (Conv2dSpec 6 16 5 5)
      <*> sample (LinearSpec 256 120)
      <*> sample (LinearSpec 120 84)
      <*> sample (LinearSpec 84 10)

-- | h_theta : [B, 784] -> [B, 10] (logits, pre-softmax)
hTheta :: MLP -> Tensor -> Tensor
hTheta MLP {..} input =
  let 
      -- Input structure from general bounds defaults to flat vectors. 
      -- We remap into independent spatial chunks `[Batch, Channels=1, Height=28, Width=28]`
      b = head (Torch.shape input)
      input2d = Torch.reshape [b, 1, 28, 28] input
      
      Conv2d cp_w1 cp_b1 = conv1
      w1 = toDependent cp_w1
      b1 = toDependent cp_b1
      -- Conv1: [B, 1, 28, 28] -> [B, 6, 24, 24] -> MaxPool -> [B, 6, 12, 12]
      c1 = F.maxPool2d (2, 2) (2, 2) (0, 0) (1, 1) F.Floor 
           $ F.elu (1.0 :: Float) 
           $ F.conv2d w1 b1 (1, 1) (0, 0) (1, 1) 1 input2d
           
      Conv2d cp_w2 cp_b2 = conv2
      w2 = toDependent cp_w2
      b2 = toDependent cp_b2
      -- Conv2: [B, 6, 12, 12] -> [B, 16, 8, 8] -> MaxPool -> [B, 16, 4, 4]
      c2 = F.maxPool2d (2, 2) (2, 2) (0, 0) (1, 1) F.Floor 
           $ F.elu (1.0 :: Float) 
           $ F.conv2d w2 b2 (1, 1) (0, 0) (1, 1) 1 c1
           
      -- Flatten into 1D for classic Multi-Layer Perceptron resolution
      flat = Torch.reshape [b, 16 * 4 * 4] c2
      
      -- Fully Connected Layers
      l1 = F.elu (1.0 :: Float) $ linear fc1 flat
      l2 = F.elu (1.0 :: Float) $ linear fc2 l1
      l3 = linear fc3 l2
   in l3


-- | Default definition (renamed to MLP purely to avoid refactoring outer dependency graph naming)
mnistSpec :: MLPSpec
mnistSpec = MLPSpec

{-# NOINLINE currentModel #-}
currentModel :: MLP
currentModel = unsafePerformIO $ do
  m <- sample mnistSpec
  return (toDevice (Device MPS 0) m)
