{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Executable for Binary Classification (TensReal) using JIT training.
module Main where

import C_Domain.F_Interpretation.BinaryRealMLP (hThetaReal)
import D_Grammatical.F_Interpretation.BinaryFormulasReal (axiomReal)
import C_Domain.G_Parameters.BinaryTrainingRealJIT (trainBinaryRealJIT)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensReal (JIT Compiled) Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryRealJIT 1000 0.001 axiomReal

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels (Torch.sigmoid (hThetaReal finalModel testData)) testLabels
  putStrLn "Finished."
