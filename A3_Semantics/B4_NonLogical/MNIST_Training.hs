{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | MNIST Training: inductive learning via the formula
--   forall (x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
module A3_Semantics.B4_NonLogical.MNIST_Training
  ( trainMNIST,
  )
where

import A1_Syntax.B4_NonLogical.MNIST_Vocab (MNIST_Vocab (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import A2_Interpretation.B4_NonLogical.MNIST (mnistMapTENS, setGlobalMLP)
import A2_Interpretation.B4_NonLogical.MNIST_MLP (MLP, hTheta, mnistSpec)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Typed.Tensor (toDynamic)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import qualified Data.Map.Strict as Map

import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Device (Device(..), DeviceType(..))
import Torch.Tensor (toDevice)

-- | The tensor table as a flat list of training entries.
--   Each entry: ((image1_tensor, image2_tensor), sum_digit_tensor)
--   This IS the vectorial database. Pre-built, fixed at load time.
{-# NOINLINE tensTable #-}
tensTable :: [((Image TENS, Image TENS), Digit TENS)]
tensTable = Map.toList mnistMapTENS

-- | Training loop: Adam optimizer on -log(truthValue) Mini-batches
trainMNIST :: Int -> Float -> IO MLP
trainMNIST numEpochs learningRate = do
  initModel <- return . toDevice (Device MPS 0) =<< sample mnistSpec
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
  
  putStrLn $ "[Training] " ++ show numEpochs ++ " epochs, batch size=32, Adam lr=" ++ show learningRate
  let batchSize = 32
      batches = chunksOf batchSize tensTable

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

-- | Batch loss: operates entirely in TENS, directly from the tensor table.
--   Each batch entry is ((img1_tensor, img2_tensor), sum_digit_tensor).
batchLoss :: MLP -> [((Image TENS, Image TENS), Digit TENS)] -> Torch.Tensor
batchLoss m batch =
  let -- Stack the tensor images from the table into batches: [B, 784]
      img1s = Torch.stack (Torch.Dim 0) [toDynamic (fst (fst entry)) | entry <- batch]
      img2s = Torch.stack (Torch.Dim 0) [toDynamic (snd (fst entry)) | entry <- batch]
      
      -- Ground truth targets: already in the table. Just stack them: [B, 19]
      targets = Torch.stack (Torch.Dim 0) [snd entry | entry <- batch]
      
      -- Execute MLP on the batched images: [B, 784] -> [B, 10]
      batchDx = hTheta m img1s
      batchDy = hTheta m img2s
      
      -- Batched convolution digitPlus: [B, 10] + [B, 10] -> [B, 19]
      batchSum = digitPlus @TENS batchDx batchDy
      
      -- Batched truth logic digitEq: P(a=b) -> [B, 1]
      batchLogTVsTyped = digitEq @TENS batchSum targets
      batchLogTVs = toDynamic batchLogTVsTyped
      
      -- Negative log-likelihood loss
      total = Torch.sumAll batchLogTVs
    in (Torch.zeros' [] - total) / Torch.asTensor (fromIntegral (length batch) :: Float)

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

-- | Fold with monadic accumulator
foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
