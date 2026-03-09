{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | MNIST Training: inductive learning via the formula
--   forall (x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
module D_Inference.D_NonLogical.MNIST_Training
  ( trainMNIST,
  )
where

import A_Syntax.D_NonLogical.MNIST_Vocab (MNIST_Vocab (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.D_NonLogical.MNIST (mnistTableTENS, setGlobalMLP)
import B_Interpretation.D_NonLogical.MNIST_MLP (MLP, hTheta, mnistSpec)
import Data.List (foldl')
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (toDynamic)

-- | The tensor table: each entry is (image1, image2, sum_digit).
--   The sum digit comes directly from mnistTableTENS (= add's table).
{-# NOINLINE tensTable #-}
tensTable :: [(Image TENS, Image TENS, Digit TENS)]
tensTable = mnistTableTENS

-- | Training loop: Adam optimizer on -log(truthValue) Mini-batches
trainMNIST :: Int -> Float -> IO MLP
trainMNIST numEpochs learningRate = do
  initModel <- return . toDevice (Device MPS 0) =<< sample mnistSpec
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)

  putStrLn $ "[Training] " ++ show numEpochs ++ " epochs, batch size=32, Adam lr=" ++ show learningRate
  let batchSize = 32
      rawBatches = chunksOf batchSize tensTable
      -- Pre-stack the tensors into native GPU batch matrices so we don't pay
      -- the FFI overhead of Torch.stack on lists during every single epoch.
      batches =
        [ ( Torch.stack (Torch.Dim 0) [toDynamic i1 | (i1, _, _) <- b],
            Torch.stack (Torch.Dim 0) [toDynamic i2 | (_, i2, _) <- b],
            Torch.stack (Torch.Dim 0) [d | (_, _, d) <- b],
            Torch.toDevice (Device MPS 0) (Torch.asTensor ((-1.0) / fromIntegral (length b) :: Float))
          )
          | b <- rawBatches
        ]

  -- Force absolute evaluation of the pre-stacked batches to guarantee they reside in MPS memory
  let !_ = foldl' (\acc (i1, i2, d, lenRecip) -> acc `seq` i1 `seq` i2 `seq` d `seq` lenRecip `seq` ()) () batches

  startTime <- getCurrentTime

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    epochStart <- getCurrentTime
    -- process each batch
    ((newModel, newOpt), batchTimes) <- foldLoop ((model, opt), [] :: [Double]) batches $ \((m, o), times) batch -> do
      bStart <- getCurrentTime
      let avgLoss = batchLoss m batch
          lr = Torch.asTensor learningRate
      (m', o') <- runStep m o avgLoss lr
      bEnd <- getCurrentTime
      let bDiff = realToFrac (diffUTCTime bEnd bStart) * 1000 :: Double
      return ((m', o'), bDiff : times)

    let validTimes = if length batchTimes > 1 then tail (reverse batchTimes) else batchTimes
        meanT = sum validTimes / fromIntegral (length validTimes)
        stdT = sqrt (sum [(t - meanT) ^ (2 :: Int) | t <- validTimes] / fromIntegral (length validTimes))
    putStrLn $ printf "  -> %.2f ± %.2f ms/batch" meanT stdT

    epochEnd <- getCurrentTime
    -- calculate loss on first batch for reporting
    let lossVal = Torch.asValue (batchLoss newModel (head batches)) :: Float
    let diff = realToFrac (diffUTCTime epochEnd epochStart) :: Double
    putStrLn $ printf "[Epoch %2d/%d] Loss = %8.6f | Time: %5.2fs" epoch numEpochs lossVal diff
    return (newModel, newOpt)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] Total Time: %5.2fs" totalDiff

  -- Publish the final fully trained weights to the DATA interpreter
  setGlobalMLP finalModel

  return finalModel

-- | Batch loss: operates entirely in TENS, from the pre-joined tensor table.
batchLoss :: MLP -> (Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor) -> Torch.Tensor
batchLoss m (img1s, img2s, targets, batchLenRecip) =
  let -- Execute MLP on the batched images: [B, 784] -> [B, 10]
      batchDx = hTheta m img1s
      batchDy = hTheta m img2s

      -- Batched convolution digitPlus: [B, 10] + [B, 10] -> [B, 19]
      batchSum = digitPlus @TENS batchDx batchDy

      -- Batched truth logic digitEq: P(a=b) -> [B, 1]
      batchLogTVsTyped = digitEq @TENS batchSum targets
      batchLogTVs = toDynamic batchLogTVsTyped

      -- Negative log-likelihood loss
      total = Torch.sumAll batchLogTVs
   in total * batchLenRecip

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

-- | Fold with monadic accumulator
foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
