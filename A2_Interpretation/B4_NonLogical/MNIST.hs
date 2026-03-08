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
import Torch (Randomizable(..), asTensor)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional as F
import Torch.Typed.Tensor (Tensor(UnsafeMkTensor), toDynamic)
import qualified Torch.Tensor as Torch
import Torch.Tensor (toDevice)
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
mnistMapDATA :: Map.Map (Int, Int) Int
mnistMapDATA = Map.fromList [((im1 r, im2 r), sumLabel r) | r <- mnistTable]

instance MNIST_Vocab DATA where
  type Image DATA = Int
  type Digit DATA = Int
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

-- | The MNIST addition table in TENS: a simple pre-built vectorial database.
--   Keys are tensor images, values are tensor digits. Fixed at load time.
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

  -- Simple lookup in the pre-built tensor table. That's all add does.
  add :: (Image TENS, Image TENS) -> Digit TENS
  add (x, y) = mnistMapTENS Map.! (x, y)

  digitPlus :: Digit TENS -> Digit TENS -> Digit TENS
  digitPlus p1 p2 =
    -- True Continuous Logarithmic Convolution. 
    -- To strictly prevent probability underflow bounds prior to the loss evaluation, 
    -- we map `digitPlus` purely inside logarithmic topological space (`Log-of-Sums`) via LogSumExp matrices.
    let l1 = F.logSoftmax (Torch.Dim 1) p1
        l2 = F.logSoftmax (Torch.Dim 1) p2
        shapeData = Torch.shape l1
        b = head shapeData :: Int     -- Batch size
        n = shapeData !! 1 :: Int     -- 10

        l1_exp = Torch.reshape [b, n, 1] l1
        l2_exp = Torch.reshape [b, 1, n] l2
        sum_mat = l1_exp + l2_exp -- [B, 10, 10] matrix of log(P(x) * P(y))
        
        -- Geometrical masking matrix combining discrete bounds
        mkMask :: Int -> [[Float]]
        mkMask k = [ [ if i + j == k then (0.0 :: Float) else (-1e20 :: Float) | j <- [0..n-1] ] | i <- [0..n-1] ]
        masks = Torch.toDevice (Torch.device p1) $ Torch.asTensor [ mkMask k | k <- [0..n+n-2] ]
        
        mask_exp = Torch.reshape [1, n + n - 1, n, n] masks
        sum_mat_exp = Torch.reshape [b, 1, n, n] sum_mat
        
        combined = sum_mat_exp + mask_exp -- [B, 19, 10, 10]
        
        -- LogSumExp reduction flawlessly calculates logical probability without floating boundary collapse
     in Torch.logsumexp False 2 (Torch.logsumexp False 2 combined)

  digitEq :: Digit TENS -> Digit TENS -> Omega TENS
  digitEq logA b =
    -- Because batchSum `logA` is already computed purely natively inside logarithmic tensors,
    -- we immediately map the Sum-of-Logs Cross-Entropy without invoking `log(x+eps)` boundaries.
    let logProbEqual = Torch.sumDim (Torch.Dim 1) Torch.KeepDim Torch.Float (b * logA)
     in UnsafeMkTensor logProbEqual

-- ============================================================
--  BRIDGE: Encoding/Decoding between DATA and TENS
-- ============================================================

instance MNIST_Bridge DATA TENS where
  encImage :: Image DATA -> Image TENS
  encImage idx = UnsafeMkTensor (Torch.toDevice (Device MPS 0) $ Torch.select 0 (fromIntegral idx) mnistImages)

  encDigit :: Digit DATA -> Digit TENS
  encDigit d =
    let idx = fromIntegral d :: Int
        zeros = replicate 19 (0.0 :: Float)
        oneHot = take idx zeros ++ [1.0] ++ drop (idx + 1) zeros
     in Torch.toDevice (Device MPS 0) (asTensor oneHot)

  decDigit :: Digit TENS -> (M DATA) (Digit DATA)
  decDigit logits =
    -- The MNIST logic runs over 5000 images, and Dist evaluates full list permutations mathematically! 
    -- Returning 10 fractional SoftMax permutations expands the list into $10 * 10 = 100$ branches per row, 
    -- resulting in $100^{5000}$ RAM permutation branches! We MUST collapse the neural outcome via deterministic Top-1 ArgMax.
    let maxIdx = Torch.asValue (Torch.argmax (Torch.Dim 0) Torch.RemoveDim logits) :: Int
     in Dist [(fromIntegral maxIdx, 1.0)]
