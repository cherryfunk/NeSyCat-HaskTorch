{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import qualified B_Logical.F_Interpretation.Tensor as TENS
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
import D_Grammatical.F_Interpretation.BinaryIntpTens (binaryAxiomTens)
import C_Domain.F_Interpretation.BinaryReal ()
import E_Inference.F_Interpretation.InferenceIntpTens ()
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

main :: IO ()
main = do
  let nRuns = 100 :: Int
  putStrLn "=== 100-run comparison: fixed beta=1.0 vs learnable beta (init=2.0) ==="
  results <- mapM (\i -> do
    -- Shared dataset per run
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

    -- Fixed beta=1.0
    m1 <- train 1000 0.001 1.0 False trainData trainLabels
    let f1_fix = f1Score (Torch.sigmoid (hThetaReal m1 testData)) testLabels
        ac_fix = accuracy (Torch.sigmoid (hThetaReal m1 testData)) testLabels

    -- Learnable beta (init=2.0)
    (m2, finalBeta) <- trainBeta 1000 0.001 2.0 trainData trainLabels
    let f1_lrn = f1Score (Torch.sigmoid (hThetaReal m2 testData)) testLabels
        ac_lrn = accuracy (Torch.sigmoid (hThetaReal m2 testData)) testLabels

    if i `mod` 10 == 0
      then putStrLn $ printf "  [%3d/100] fix: F1=%.3f  learn: F1=%.3f (beta=%.3f)" i f1_fix f1_lrn finalBeta
      else return ()

    return (f1_fix, ac_fix, f1_lrn, ac_lrn, finalBeta)
    ) [1..nRuns]

  let (fs1, as1, fs2, as2, bs) = unzip5 results
      avg xs = sum xs / fromIntegral (length xs)
      std xs = let m = avg xs; n = fromIntegral (length xs) in sqrt (sum (map (\x -> (x-m)*(x-m)) xs) / n)
      mn xs = minimum xs
      mx xs = maximum xs

  putStrLn ""
  putStrLn "=== Results (100 runs) ==="
  putStrLn $ printf "%-20s  %-10s %-10s %-10s %-10s" ("" :: String) ("Avg" :: String) ("Std" :: String) ("Min" :: String) ("Max" :: String)
  putStrLn (replicate 64 '-')
  putStrLn $ printf "%-20s  %-10.4f %-10.4f %-10.4f %-10.4f" ("Fixed F1" :: String) (avg fs1) (std fs1) (mn fs1) (mx fs1)
  putStrLn $ printf "%-20s  %-10.4f %-10.4f %-10.4f %-10.4f" ("Fixed Acc" :: String) (avg as1) (std as1) (mn as1) (mx as1)
  putStrLn $ printf "%-20s  %-10.4f %-10.4f %-10.4f %-10.4f" ("Learnable F1" :: String) (avg fs2) (std fs2) (mn fs2) (mx fs2)
  putStrLn $ printf "%-20s  %-10.4f %-10.4f %-10.4f %-10.4f" ("Learnable Acc" :: String) (avg as2) (std as2) (mn as2) (mx as2)
  putStrLn $ printf "%-20s  %-10.4f %-10.4f %-10.4f %-10.4f" ("Learned beta" :: String) (avg bs) (std bs) (mn bs) (mx bs)

  -- Count wins
  let fixWins = length (filter (\(a,b) -> a > b) (zip fs1 fs2))
      lrnWins = length (filter (\(a,b) -> b > a) (zip fs1 fs2))
      ties    = nRuns - fixWins - lrnWins
  putStrLn ""
  putStrLn $ printf "F1 wins: Fixed=%d  Learnable=%d  Ties=%d" fixWins lrnWins ties

-- Fixed-beta training (silent)
train :: Int -> Float -> Float -> Bool -> Torch.Tensor -> Torch.Tensor -> IO Binary_MLP
train epochs lr beta _ trainData trainLabels = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
      betaT = Torch.asTensor beta
      lrT = Torch.toDevice (Device CPU 0) (Torch.asTensor lr)
      nT = Torch.toDevice (Device CPU 0) (Torch.asTensor (50.0 :: Float))
  (m, _) <- foldLoop (initModel, initOpt) [1..epochs] $ \(model, opt) _ -> do
    let sat = toDynamic (binaryAxiomTens betaT trainData model)
        loss = negate (Torch.log (Torch.sigmoid sat))
    (nm, no) <- runStep model opt loss lrT
    return (nm, no)
  return m

-- Learnable-beta training (silent)
trainBeta :: Int -> Float -> Float -> Torch.Tensor -> Torch.Tensor -> IO (Binary_MLP, Float)
trainBeta epochs lr initBeta trainData trainLabels = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
      lrT = Torch.toDevice (Device CPU 0) (Torch.asTensor lr)
  betaInd <- Torch.makeIndependent (Torch.asTensor initBeta)
  (m, _, bFinal) <- foldLoop (initModel, initOpt, betaInd) [1..epochs] $ \(model, opt, bInd) _ -> do
    let betaVal = Torch.toDependent bInd
        sat = toDynamic (binaryAxiomTens betaVal trainData model)
        loss = negate (Torch.log (Torch.sigmoid sat))
    (nm, no) <- runStep model opt loss lrT
    -- Step beta via manual SGD, clamp > 0.01
    let grads = Torch.grad loss [bInd]
        gB = head grads
        lrB = Torch.asTensor lr
        newB = betaVal `Torch.sub` (gB `Torch.mul` lrB)
        epsT = Torch.asTensor (0.01 :: Float)
        clamped = Torch.relu (newB `Torch.sub` epsT) `Torch.add` epsT
    newBInd <- Torch.makeIndependent clamped
    return (nm, no, newBInd)
  let finalBeta = Torch.asValue (Torch.toDependent bFinal) :: Float
  return (m, finalBeta)

accuracy :: Torch.Tensor -> Torch.Tensor -> Float
accuracy preds labels =
  let predBool  = Torch.ge preds (Torch.asTensor (0.5 :: Float))
      labelBool = Torch.ge labels (Torch.asTensor (0.5 :: Float))
      correct   = Torch.eq predBool labelBool
      n         = fromIntegral (head (Torch.shape preds)) :: Float
   in Torch.asValue (Torch.sumAll (Torch.toType Torch.Float correct)) / n

f1Score :: Torch.Tensor -> Torch.Tensor -> Float
f1Score preds labels =
  let predBool  = Torch.toType Torch.Float (Torch.ge preds (Torch.asTensor (0.5 :: Float)))
      tp = Torch.asValue (Torch.sumAll (predBool `Torch.mul` labels)) :: Float
      fp = Torch.asValue (Torch.sumAll (predBool `Torch.mul` (1 - labels))) :: Float
      fn = Torch.asValue (Torch.sumAll ((1 - predBool) `Torch.mul` labels)) :: Float
      prec = if tp + fp > 0 then tp / (tp + fp) else 0
      rec  = if tp + fn > 0 then tp / (tp + fn) else 0
   in if prec + rec > 0 then 2 * prec * rec / (prec + rec) else 0

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f

unzip5 :: [(a,b,c,d,e)] -> ([a],[b],[c],[d],[e])
unzip5 [] = ([],[],[],[],[])
unzip5 ((a,b,c,d,e):rest) = let (as,bs,cs,ds,es) = unzip5 rest in (a:as,b:bs,c:cs,d:ds,e:es)
