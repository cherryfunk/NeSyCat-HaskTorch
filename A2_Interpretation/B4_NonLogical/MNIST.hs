{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | MNIST — All three instances in one module:
--   1. MNIST_Vocab DATA   (data category, Dist monad)
--   2. MNIST_Vocab TENS   (tensor spaces, Identity monad)
--   3. MNIST_Bridge DATA TENS (encoding/decoding between the two)
module A2_Interpretation.B4_NonLogical.MNIST
  ( mnistTable,
    mnistMapDATA,
    mnistMapTENS,
    setGlobalMLP,
    module A1_Syntax.B4_NonLogical.MNIST_Vocab,
    module A2_Interpretation.B4_NonLogical.MNIST_MLP,
  )
where

import A1_Syntax.B2_Typological.TENS_Vocab ()
import A1_Syntax.B4_NonLogical.MNIST_Vocab (ImagePairRow (..), MNIST_Vocab (..), MNIST_Bridge (..))
import A2_Interpretation.B1_Categorical.Monads.Dist (Dist (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import A2_Interpretation.B3_Logical.Tensor hiding (Omega)
import A2_Interpretation.B4_NonLogical.MNIST_MLP (MLP, hTheta, mnistSpec)
import Data.Functor.Identity (Identity (..))
import qualified Data.Map.Strict as Map
import MNIST_Loader (mnistImages, mnistLabels, mnistTable)
import Numeric.Natural (Natural)
import Torch (Randomizable(..), asTensor)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import qualified Torch.Functional as F
import Torch.Typed.Tensor (Tensor(UnsafeMkTensor), toDynamic)
import qualified Torch.Tensor as Torch
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import System.IO.Unsafe (unsafePerformIO)

-- | Global IORef to store the active neural network parameters.
-- This allows the pure `DATA` typeclass to dynamically evaluate the neural perception
-- function without altering the mathematical formulas or `MNIST_Vocab` signatures.
{-# NOINLINE globalMLP #-}
globalMLP :: IORef MLP
globalMLP = unsafePerformIO $ do
  m <- sample mnistSpec
  newIORef m

setGlobalMLP :: MLP -> IO ()
setGlobalMLP = writeIORef globalMLP

-- ============================================================
--  DATA: The MNIST addition table
-- ============================================================

{-# NOINLINE mnistMapDATA #-}
mnistMapDATA :: Map.Map (Natural, Natural) Natural
mnistMapDATA = Map.fromList [((im1 r, im2 r), sumLabel r) | r <- mnistTable]

instance MNIST_Vocab DATA where
  type Image DATA = Natural
  type Digit DATA = Natural
  type Omega DATA = Bool
  type M DATA = Dist

  -- The definition of 'digit' in DATA is exactly the evaluation of the Learned Neural Model
  digit :: Image DATA -> (M DATA) (Digit DATA)
  digit idx = unsafePerformIO $ do
    m <- readIORef globalMLP
    -- We evaluate the neural network on-demand for this specific image 
    let imgTens = toDynamic (encImage @DATA @TENS idx)
        logits  = hTheta m (Torch.reshape [1, 784] imgTens)
    return (decDigit @DATA @TENS (Torch.reshape [10] logits))

  add :: (Image DATA, Image DATA) -> Digit DATA
  add (idx1, idx2) = mnistMapDATA Map.! (idx1, idx2)

  digitPlus :: Digit DATA -> Digit DATA -> Digit DATA
  digitPlus x y = x + y

  digitEq :: Digit DATA -> Digit DATA -> Omega DATA
  digitEq x y = x == y

-- ============================================================
--  TENS: tensor-space interpretation
-- ============================================================

{-# NOINLINE mnistMapTENS #-}
mnistMapTENS :: Map.Map (Image TENS, Image TENS) (Digit TENS)
mnistMapTENS = Map.fromList [((encImage @DATA @TENS k1, encImage @DATA @TENS k2), encDigit @DATA @TENS v) | ((k1, k2), v) <- Map.toList mnistMapDATA]

instance MNIST_Vocab TENS where
  type Image TENS = Tensor '( 'CPU, 0) 'Float '[784]
  type Digit TENS = Torch.Tensor
  type Omega TENS = Tensor '( 'CPU, 0) 'Float '[1]
  type M TENS = Identity

  digit :: Image TENS -> M TENS (Digit TENS)
  digit imgTensor = Identity $ unsafePerformIO $ do
    m <- readIORef globalMLP
    return (hTheta m (toDynamic imgTensor))

  add :: (Image TENS, Image TENS) -> Digit TENS
  add (x, y) = mnistMapTENS Map.! (x, y)

  digitPlus :: Digit TENS -> Digit TENS -> Digit TENS
  digitPlus p1 p2 =
    -- Input shape is [B, 10]
    let p1' = F.softmax (Torch.Dim 1) p1
        p2' = F.softmax (Torch.Dim 1) p2
        shapeData = Torch.shape p1'
        b = head shapeData :: Int     -- Batch size
        n = shapeData !! 1 :: Int     -- 10

        -- reverse p1' along dim=1 because PyTorch conv1d computes true cross-correlation
        indices   = Torch.asTensor [n - 1, n - 2 .. 0]
        kernel_1d = Torch.indexSelect 1 indices p1'
        
        -- weight shape: [out_channels=B, in_channels/groups=1, length=n]
        weight = Torch.reshape [b, 1, n] kernel_1d
        -- input shape:  [batch=1, in_channels=B, length=m]
        inputGrouped = Torch.reshape [1, b, n] p2'
        bias   = Torch.zeros' [b]
        
        -- f(weight, bias, stride=1, padding=n-1, dilation=1, groups=b, inputGrouped) -> output shape [1, B, 19]
        conv   = F.conv1d weight bias 1 (n - 1) 1 b inputGrouped
     in Torch.reshape [b, n + n - 1] conv

  digitEq :: Digit TENS -> Digit TENS -> Omega TENS
  digitEq a b =
    -- a is [B, 19], b is [B, 19]
    -- P(a == b) = sum(a_i * b_i) independently per batch row
    let probEqual = Torch.sumDim (Torch.Dim 1) Torch.KeepDim Torch.Float (a * b)
     in UnsafeMkTensor probEqual

-- ============================================================
--  BRIDGE: Encoding/Decoding between DATA and TENS
-- ============================================================

instance MNIST_Bridge DATA TENS where
  encImage :: Image DATA -> Image TENS
  encImage idx = UnsafeMkTensor (Torch.select 0 (fromIntegral idx) mnistImages)

  encDigit :: Digit DATA -> Digit TENS
  encDigit d =
    let idx = fromIntegral d :: Int
        zeros = replicate 19 (0.0 :: Float)
        oneHot = take idx zeros ++ [1.0] ++ drop (idx + 1) zeros
     in asTensor oneHot

  decDigit :: Digit TENS -> (M DATA) (Digit DATA)
  decDigit logits =
    -- The MNIST logic runs over 5000 images, and Dist evaluates full list permutations mathematically! 
    -- Returning 10 fractional SoftMax permutations expands the list into $10 * 10 = 100$ branches per row, 
    -- resulting in $100^{5000}$ RAM permutation branches! We MUST collapse the neural outcome via deterministic Top-1 ArgMax.
    let maxIdx = Torch.asValue (Torch.argmax (Torch.Dim 0) Torch.RemoveDim logits) :: Int
     in Dist [(fromIntegral maxIdx, 1.0)]
