-- | Train binary classification (fixed beta).
--
--   Usage:
--     cabal run binary-test-real              -- default beta=1.75, lambda=1.0
--     cabal run binary-test-real -- 1.75 1.0  -- explicit beta and lambda
module Main where

import BinaryTrainLib (generateBinaryDataset, trainBinary)
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  let beta   = case args of { (b:_) -> read b; _ -> 1.75 :: Float }
      lambda = case args of { (_:l:_) -> read l; _ -> 1.0 :: Float }
  ds <- generateBinaryDataset
  _ <- trainBinary 1000 0.001 lambda beta ds
  return ()
