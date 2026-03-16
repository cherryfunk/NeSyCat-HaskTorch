{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | JIT Training loop for Binary Classification using TensReal logic.
module C_NonLogical.G_Parameters.BinaryTrainingRealJIT
  ( trainBinaryRealJIT,
  )
where

import C_NonLogical.F_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal)
import C_NonLogical.F_Interpretation.BinaryReal (setGlobalBinaryMLP)
import qualified B_Logical.F_Interpretation.Tensor as TENS
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..), replaceParameters, sample)
import qualified Torch
import Torch.Autograd (IndependentTensor (..), toDependent)
import Torch.Device (Device (..), DeviceType (..))
import Torch.NN (HasForward (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Script (IValue (..), ScriptModule, toScriptModule, trace)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Generic param packing: works for ANY Parameterized model.
packParams :: [Torch.Tensor] -> Torch.Tensor
packParams ts = Torch.cat (Torch.Dim 0) (map Torch.flattenAll ts)

-- | Generic param unpacking using recorded shapes.
unpackParams :: [[Int]] -> Torch.Tensor -> [Torch.Tensor]
unpackParams shapes packed = go 0 shapes
  where
    go _ [] = []
    go offset (sh : rest) =
      let sz = product sh
          t = Torch.reshape sh $ Torch.sliceDim 0 offset (offset + sz) 1 packed
       in t : go (offset + sz) rest

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f

-- | JIT Training loop (TensReal).
--   The axiom takes training data (empirical measure) and the model.
trainBinaryRealJIT :: Int -> Float -> (Torch.Tensor -> Binary_MLP -> TENS.Omega) -> IO (Binary_MLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
trainBinaryRealJIT numEpochs learningRate kbSatFormula = do
  initModel <- return . Torch.toDevice (Device CPU 0) =<< sample binarySpecReal

  dataset <- Torch.toDevice (Device CPU 0) <$> Torch.randIO' [100, 2]
  let center = Torch.toDevice (Device CPU 0) (Torch.asTensor ([0.5, 0.5] :: [Float]))
      diffs = dataset - center
      sq = diffs * diffs
      distances = Torch.sumDim (Torch.Dim 1) Torch.RemoveDim Torch.Float sq
      labelsBool = distances `Torch.lt` Torch.asTensor (0.09 :: Float)
      labels = Torch.toType Torch.Float labelsBool
      trainData = Torch.sliceDim 0 0 50 1 dataset
      trainLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 labels)
      testData = Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 dataset)
      testLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 labels))

  let !_ = trainData `seq` trainLabels `seq` testData `seq` testLabels `seq` ()
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
  let paramShapes = map Torch.shape (map toDependent (flattenParameters initModel))
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)

  putStrLn $ "[COMPILED Training] " ++ show numEpochs ++ " epochs, empirical measure (" ++ show (50 :: Int) ++ " pts), Adam lr=" ++ show learningRate

  jitStart <- getCurrentTime

  -- 1. Compile the computational graph using `torch.jit.trace`
  let initPacked = packParams (map toDependent (flattenParameters initModel))
  rawMod <- trace "axiom" "forward"
    (\[d, pp] -> do
       let paramTensors = unpackParams paramShapes pp
           model = replaceParameters initModel (map IndependentTensor paramTensors)
           sat = kbSatFormula d model
           satDyn = toDynamic sat
           loss = negate (Torch.log (Torch.sigmoid satDyn))
       return [loss]
    )
    [trainData, initPacked]
  scriptMod <- toScriptModule rawMod

  traceEnd <- getCurrentTime
  let traceTime = realToFrac (diffUTCTime traceEnd jitStart) :: Double
  putStrLn $ printf "  [Trace time: %5.2fs]" traceTime

  -- 2. Execute training loop using the compiled graph
  (finalParams, _) <- foldLoop (flattenParameters initModel, initOpt) [1..numEpochs] $ \(params, opt) epoch -> do
    let paramTensors = map toDependent params
        packedParams = packParams paramTensors
        tempModel = replaceParameters initModel params
        result = forward scriptMod [IVTensor trainData, IVTensor packedParams]
    case result of
      IVTensor jitLoss -> do
        (newModel, newOpt) <- runStep tempModel opt jitLoss lrTens
        let newParams = flattenParameters newModel
        if epoch `mod` 100 == 0 || epoch == 1 || epoch == numEpochs
          then do
            now <- getCurrentTime
            let lv = Torch.asValue jitLoss :: Float
                ms = (realToFrac (diffUTCTime now jitStart) :: Double) * 1000
            putStrLn $ printf "[Epoch %3d/%d] Loss=%7.5f | %.2fms" epoch numEpochs lv ms
          else return ()
        return (newParams, newOpt)
      IVTensorList (jitLoss:_) -> do
        (newModel, newOpt) <- runStep tempModel opt jitLoss lrTens
        let newParams = flattenParameters newModel
        if epoch `mod` 100 == 0 || epoch == 1 || epoch == numEpochs
          then do
            now <- getCurrentTime
            let lv = Torch.asValue jitLoss :: Float
                ms = (realToFrac (diffUTCTime now jitStart) :: Double) * 1000
            putStrLn $ printf "[Epoch %3d/%d] Loss=%7.5f | %.2fms" epoch numEpochs lv ms
          else return ()
        return (newParams, newOpt)
      _ -> error "JIT returned unexpected type"

  jitEnd <- getCurrentTime
  let jitTime = realToFrac (diffUTCTime jitEnd jitStart) :: Double
  putStrLn $ printf "[Training complete] Total Time (incl. trace): %5.2fs" jitTime

  let finalModel = replaceParameters initModel finalParams
  setGlobalBinaryMLP finalModel

  return (finalModel, trainData, trainLabels, testData, testLabels)
