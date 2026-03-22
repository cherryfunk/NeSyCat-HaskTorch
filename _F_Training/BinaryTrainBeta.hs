-- | Train binary classification with learnable beta.
--
--   Usage:
--     cabal run binary-test-real-beta              -- default lambda=1.0, init_beta=2.0
--     cabal run binary-test-real-beta -- 1.0       -- explicit lambda
module Main where

import BinaryTrainLib (generateBinaryDataset, trainBinaryBeta)
import System.Environment (getArgs)
import Text.Printf (printf)
import qualified Torch

main :: IO ()
main = do
  args <- getArgs
  let lambda = case args of { (x:_) -> read x; _ -> 1.0 :: Float }
  ds <- generateBinaryDataset
  (_, learnedBeta) <- trainBinaryBeta 1000 0.001 2.0 lambda ds
  putStrLn $ printf "Learned beta: %.4f" (Torch.asValue learnedBeta :: Float)
