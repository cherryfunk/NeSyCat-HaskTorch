{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation: Binary classification domain (learnable beta).
module Main where

import C_Domain.A_Category.Data (DATA (..))
import C_Domain.D_Theory.BinaryTheory (BinaryKlFun (classifierA))
import C_Domain.G_Parameters.BinaryTrainingRealBeta (trainBinaryRealBeta)
import D_Grammatical.D_Theory.BinaryFormulasRealBeta (axiomRealBeta)
import F_Benchmark.Metrics.Metrics (evaluateMetrics)
import C_Domain.F_Interpretation.BinaryReal ()
import C_Domain.F_Interpretation.BinaryRealMLP (hThetaReal)
import qualified Torch
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  let lambda = case args of { (x:_) -> read x; _ -> 0.0 :: Float }

  -- Train: optimize theta and beta jointly
  (finalModel, learnedBeta, trainData, trainLabels, testData, testLabels) <-
    trainBinaryRealBeta 1000 0.001 1.25 lambda axiomRealBeta

  putStrLn $ "Learned beta: " ++ show (Torch.asValue learnedBeta :: Float)

  -- Evaluate: push back via sigmoid
  evaluateMetrics
    (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels
    (Torch.sigmoid (hThetaReal finalModel testData)) testLabels

  -- Inference in DATA category
  print (classifierA @DATA () (0.5 :: Float, 0.5 :: Float))
  print (classifierA @DATA () (0.9 :: Float, 0.9 :: Float))
