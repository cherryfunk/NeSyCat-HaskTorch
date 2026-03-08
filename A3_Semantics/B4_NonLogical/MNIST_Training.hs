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
import A2_Interpretation.B4_NonLogical.MNIST ()
-- bring instances into scope
import A2_Interpretation.B4_NonLogical.MNIST_MLP (MLP, hTheta, mnistSpec)
import MNIST_Loader (mnistTable)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Typed.Tensor (toDynamic)

import Torch.Optim (Adam (..), mkAdam, runStep)

-- | Training loop: Adam optimizer on -log(truthValue) Mini-batches
trainMNIST :: Int -> Float -> IO MLP
trainMNIST numEpochs learningRate = do
  initModel <- sample mnistSpec
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
  
  putStrLn $ "[Training] " ++ show numEpochs ++ " epochs, batch size=32, Adam lr=" ++ show learningRate
  let batchSize = 32
      batches = chunksOf batchSize mnistTable

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    -- process each batch
    (newModel, newOpt) <- foldLoop (model, opt) batches $ \(m, o) batch -> do
      let avgLoss = batchLoss m batch
          lr = Torch.asTensor learningRate
      runStep m o avgLoss lr

    -- calculate loss on first batch for reporting
    let lossVal = Torch.asValue (batchLoss newModel (head batches)) :: Float
    putStrLn $ "[Epoch " ++ show epoch ++ "/" ++ show numEpochs ++ "] Loss = " ++ show lossVal
    return (newModel, newOpt)
    
  return finalModel

batchLoss :: MLP -> [ImagePairRow] -> Torch.Tensor
batchLoss m batch =
  -- 1. Stack raw data into native PyTorch batches: [B, 784]
  let img1s = Torch.stack (Torch.Dim 0) [toDynamic (encImage @DATA @TENS (im1 row)) | row <- batch]
      img2s = Torch.stack (Torch.Dim 0) [toDynamic (encImage @DATA @TENS (im2 row)) | row <- batch]
      targets = Torch.stack (Torch.Dim 0) [encDigit @DATA @TENS (sumLabel row) | row <- batch]
      
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
