{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | MNIST Training: inductive learning via the formula
--   forall (x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
module A3_Semantics.B4_NonLogical.MNIST_Training
  ( trainMNIST,
  )
where

import A1_Syntax.B4_NonLogical.MNIST_Vocab (ImagePairRow (..), MNIST_Bridge (..), MNIST_Vocab (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import A2_Interpretation.B4_NonLogical.MNIST (setGlobalMLP)
import A2_Interpretation.B4_NonLogical.MNIST_MLP (MLP, hTheta, mnistSpec)
import MNIST_Loader (mnistImages, mnistTable)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Typed.Tensor (toDynamic)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)

import Torch.Optim (Adam (..), mkAdam, runStep)

-- | Training loop: Adam optimizer on -log(truthValue) Mini-batches
trainMNIST :: Int -> Float -> IO MLP
trainMNIST numEpochs learningRate = do
  initModel <- sample mnistSpec
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
  
  putStrLn $ "[Training] " ++ show numEpochs ++ " epochs, batch size=32, Adam lr=" ++ show learningRate
  let batchSize = 32
      batches = chunksOf batchSize mnistTable

  startTime <- getCurrentTime

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    epochStart <- getCurrentTime
    -- process each batch
    (newModel, newOpt) <- foldLoop (model, opt) batches $ \(m, o) batch -> do
      let avgLoss = batchLoss m batch
          lr = Torch.asTensor learningRate
      runStep m o avgLoss lr

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

batchLoss :: MLP -> [ImagePairRow] -> Torch.Tensor
batchLoss m batch =
  -- 1. Extract unified batch index tensors avoiding Haskell looping overhead
  let idx1 = Torch.asTensor [fromIntegral (im1 row) :: Int | row <- batch]
      idx2 = Torch.asTensor [fromIntegral (im2 row) :: Int | row <- batch]
      lbls = Torch.asTensor [fromIntegral (sumLabel row) :: Int | row <- batch]
      
      -- Native PyTorch memory slicing: [B, 784]
      img1s = Torch.indexSelect 0 idx1 mnistImages
      img2s = Torch.indexSelect 0 idx2 mnistImages
      
      -- Embedding lookup for batched one-hot logic targets: [B, 19]
      targets = Torch.indexSelect 0 lbls (Torch.eye' 19 19)
      
      -- 2. Execute MLP natively on the [B, 784] batches yielding [B, 10]
      batchDx = hTheta m img1s
      batchDy = hTheta m img2s
      
      -- 3. Execute batched convolution digitPlus ([B, 10] + [B, 10] -> [B, 19])
      batchSum = digitPlus @TENS batchDx batchDy
      
      -- 4. Evaluate batched truth logic P(a=b) -> [B, 1]
      batchTVsTyped = digitEq @TENS batchSum targets
      batchTVs = toDynamic batchTVsTyped
      
      -- 5. Calculate loss (-log) over the vectorized truth values
      clamped = Torch.clamp 1e-8 1.0 batchTVs
      logTVs = Torch.log clamped
      total = Torch.sumAll logTVs
   in (Torch.zeros' [] - total) / Torch.asTensor (fromIntegral (length batch) :: Float)

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

-- | Fold with monadic accumulator
foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
