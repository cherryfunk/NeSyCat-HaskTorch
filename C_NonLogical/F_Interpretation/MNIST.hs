{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | MNIST — All three instances in one module:
--   1. MnistTheory DATA   (data category, Dist monad)
--   2. MnistTheory TENS   (tensor spaces, Identity monad)
--   3. MnistBridge DATA TENS (encoding/decoding between the two)
module C_NonLogical.F_Interpretation.MNIST
  ( mnistTable,
    mnistMapDATA,
    mnistTableTENS,
    setGlobalMLP,
    module C_NonLogical.D_Theory.MnistTheory,
    module C_NonLogical.F_Interpretation.MNIST_MLP,
  )
where

import B_Logical.B_Vocabulary.TensVocab ()
import C_NonLogical.D_Theory.MnistTheory (ImagePairRow (..), MnistBridge (..), MnistTheory (..))
import C_NonLogical.A_Category.Data (DATA (..))
import B_Logical.A_Category.Tens (TENS (..))
import B_Logical.F_Interpretation.Tensor hiding (Omega, TENS)
import C_NonLogical.F_Interpretation.MNIST_MLP (MLP, hTheta, mnistSpec)
import A_Categorical.F_Interpretation.Monads.Dist (Dist (..))
import Data.Functor.Identity (Identity (..))
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Data.List (find)
import qualified Data.Map.Strict as Map
import MNIST_Loader (mnistImages, mnistLabels, mnistTable)
import System.IO.Unsafe (unsafePerformIO)
import Torch (Randomizable (..), asTensor)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional as F
import Torch.Tensor (toDevice)
import qualified Torch.Tensor as Torch
import Torch.Typed.Tensor (Tensor (UnsafeMkTensor), toDynamic)

-- | Global IORef to store the active neural network parameters.
-- This allows the pure `DATA` typeclass to dynamically evaluate the neural perception
-- function without altering the mathematical formulas or `MnistTheory` signatures.
{-# NOINLINE globalMLP #-}
globalMLP :: IORef MLP
globalMLP = unsafePerformIO $ do
  m <- sample mnistSpec
  newIORef (toDevice (Device MPS 0) m)

setGlobalMLP :: MLP -> IO ()
setGlobalMLP = writeIORef globalMLP

-- ============================================================
--  DATA: The MNIST addition table
-- ============================================================

{-# NOINLINE mnistMapDATA #-}
mnistMapDATA :: Map.Map (Int, Int) Int
mnistMapDATA = Map.fromList [((im1 r, im2 r), sumLabel r) | r <- mnistTable]

instance MnistTheory DATA where
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
        logits = hTheta m (Torch.reshape [1, 784] imgTens)
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

-- | Static mask tensor for digitPlus convolutions, pre-allocated on MPS 0
{-# NOINLINE digitPlusMaskTENS #-}
digitPlusMaskTENS :: Torch.Tensor
digitPlusMaskTENS = unsafePerformIO $ do
  let n = 10 :: Int
      mkMask :: Int -> [[Float]]
      mkMask k = [[if i + j == k then (0.0 :: Float) else (-1e20 :: Float) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
  return $ Torch.toDevice (Device MPS 0) $ Torch.asTensor [mkMask k | k <- [0 .. n + n - 2]]

-- | The MNIST addition table in TENS: a plain list of tuples.
--   Each entry: (image1, image2, sum_digit). Fixed at load time.
{-# NOINLINE mnistTableTENS #-}
mnistTableTENS :: [(Image TENS, Image TENS, Digit TENS)]
mnistTableTENS = [(encImage @DATA @TENS k1, encImage @DATA @TENS k2, encDigit @DATA @TENS v) | ((k1, k2), v) <- Map.toList mnistMapDATA]

instance MnistTheory TENS where
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
  add (x, y) = case Data.List.find (\(img1, img2, _) -> img1 == x && img2 == y) mnistTableTENS of
    Just (_, _, d) -> d
    Nothing -> error "add @TENS: key not in table"

  digitPlus :: Digit TENS -> Digit TENS -> Digit TENS
  digitPlus p1 p2 =
    -- True Continuous Logarithmic Convolution.
    -- To strictly prevent probability underflow bounds prior to the loss evaluation,
    -- we map `digitPlus` purely inside logarithmic topological space (`Log-of-Sums`) via LogSumExp matrices.
    let l1 = F.logSoftmax (Torch.Dim 1) p1
        l2 = F.logSoftmax (Torch.Dim 1) p2
        shapeData = Torch.shape l1
        b = head shapeData :: Int -- Batch size
        n = shapeData !! 1 :: Int -- 10
        l1_exp = Torch.reshape [b, n, 1] l1
        l2_exp = Torch.reshape [b, 1, n] l2
        sum_mat = l1_exp + l2_exp -- [B, 10, 10] matrix of log(P(x) * P(y))

        -- We use the top-level pre-allocated tensor to eliminate FFI mask overhead inside the training loop.
        mask_exp = Torch.reshape [1, n + n - 1, n, n] digitPlusMaskTENS
        sum_mat_exp = Torch.reshape [b, 1, n, n] sum_mat

        combined = sum_mat_exp + mask_exp -- [B, 19, 10, 10]
     in -- LogSumExp reduction flawlessly calculates logical probability without floating boundary collapse
        Torch.logsumexp False 2 (Torch.logsumexp False 2 combined)

  digitEq :: Digit TENS -> Digit TENS -> Omega TENS
  digitEq logA b =
    -- Because batchSum `logA` is already computed purely natively inside logarithmic tensors,
    -- we immediately map the Sum-of-Logs Cross-Entropy without invoking `log(x+eps)` boundaries.
    let logProbEqual = Torch.sumDim (Torch.Dim 1) Torch.KeepDim Torch.Float (b * logA)
     in UnsafeMkTensor logProbEqual

-- ============================================================
--  BRIDGE: Encoding/Decoding between DATA and TENS
-- ============================================================

instance MnistBridge DATA TENS where
  encImage :: Image DATA -> Image TENS
  encImage idx = UnsafeMkTensor (Torch.select 0 (fromIntegral idx) mnistImages)
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
