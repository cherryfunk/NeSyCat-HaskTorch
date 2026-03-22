-- | Train binary classification with JIT compilation.
--
--   Usage:
--     cabal run binary-test-jit-real
module Main where

import BinaryTrainLib (generateBinaryDataset, trainBinaryJIT)

main :: IO ()
main = do
  ds <- generateBinaryDataset
  _ <- trainBinaryJIT 1000 0.001 1.75 ds
  return ()
