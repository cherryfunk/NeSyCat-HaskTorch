{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | MNIST Training: inductive learning via the formula
--   forall (x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
module C_NonLogical.G_Parameters.MNIST_Training
  ( trainMNIST,
  )
where

import C_NonLogical.D_Theory.MnistTheory (MnistTheory (..))
import B_Logical.A_Category.Tens (TENS (..))
import C_NonLogical.F_Interpretation.MNIST (mnistTableTENS, setGlobalMLP)
import C_NonLogical.F_Interpretation.MNIST_MLP (MLP, hTheta, mnistSpec)
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
      batches =
        [ ( Torch.stack (Torch.Dim 0) [toDynamic i1 | (i1, _, _) <- b],
            Torch.stack (Torch.Dim 0) [toDynamic i2 | (_, i2, _) <- b],
            Torch.stack (Torch.Dim 0) [d | (_, _, d) <- b],
            Torch.toDevice (Device MPS 0) (Torch.asTensor ((-1.0) / fromIntegral (length b) :: Float))
          )
          | b <- rawBatches
        ]

  let !_ = foldl' (\acc (i1, i2, d, lenRecip) -> acc `seq` i1 `seq` i2 `seq` d `seq` lenRecip `seq` ()) () batches

  startTime <- getCurrentTime

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    epochStart <- getCurrentTime
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
    putStrLn $ printf "  -> %.2f +/- %.2f ms/batch" meanT stdT

    epochEnd <- getCurrentTime
    let lossVal = Torch.asValue (batchLoss newModel (head batches)) :: Float
    let diff = realToFrac (diffUTCTime epochEnd epochStart) :: Double
    putStrLn $ printf "[Epoch %2d/%d] Loss = %8.6f | Time: %5.2fs" epoch numEpochs lossVal diff
    return (newModel, newOpt)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] Total Time: %5.2fs" totalDiff

  setGlobalMLP finalModel

  return finalModel

-- | Batch loss: operates entirely in TENS, from the pre-joined tensor table.
batchLoss :: MLP -> (Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor) -> Torch.Tensor
batchLoss m (img1s, img2s, targets, batchLenRecip) =
  let batchDx = hTheta m img1s
      batchDy = hTheta m img2s
      batchSum = digitPlus @TENS batchDx batchDy
      batchLogTVsTyped = digitEq @TENS batchSum targets
      batchLogTVs = toDynamic batchLogTVsTyped
      total = Torch.sumAll batchLogTVs
   in total * batchLenRecip

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
