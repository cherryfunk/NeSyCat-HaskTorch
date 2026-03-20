{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation: Binary classification domain (JIT compiled).
module Main where

import C_Domain.G_Parameters.BinaryTrainingRealJIT (trainBinaryRealJIT)
import D_Grammatical.D_Theory.BinaryFormulasReal (axiomReal)
import F_Benchmark.Metrics.Metrics (evaluateMetrics)
import C_Domain.F_Interpretation.BinaryRealMLP (hThetaReal)
import qualified Torch

main :: IO ()
main = do
  -- Train: optimize theta to satisfy the axiom (JIT compiled)
  (finalModel, trainData, trainLabels, testData, testLabels) <-
    trainBinaryRealJIT 1000 0.001 axiomReal

  -- Evaluate: push back via sigmoid
  evaluateMetrics
    (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels
    (Torch.sigmoid (hThetaReal finalModel testData)) testLabels
