{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import A1_Syntax.B4_NonLogical.MNIST_Vocab (ImagePairRow (..), MNIST_Vocab (..))
import A2_Interpretation.B1_Categorical.Monads.Dist (Dist (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B3_Logical.Boolean hiding (Omega)
import A2_Interpretation.B4_NonLogical.MNIST (mnistTable)
import A3_Semantics.B4_NonLogical.MNIST_Training (trainMNIST)
import A3_Semantics.B4_NonLogical.Monads.Expectation (probDist)
import Numeric.Natural (Natural)

------------------------------------------------------
-- MNIST Formula (DATA): ∀(x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
------------------------------------------------------
mnistSen :: Dist (Omega DATA)
mnistSen = bigWedgeM (Finite mnistTable) $ \r -> do
  dx <- digit @DATA (im1 r)
  dy <- digit @DATA (im2 r)
  return (digitEq @DATA (digitPlus @DATA dx dy) (add @DATA (im1 r, im2 r)))

mnistExp1 :: Double
mnistExp1 = probDist mnistSen

------------------------------------------------------
-- EXECUTION
------------------------------------------------------
main :: IO ()
main = do
  putStrLn $ "[MNIST] Table size: " ++ show (length mnistTable) ++ " pairs"
  putStrLn $ "[MNIST DATA] P(formula) = " ++ show mnistExp1

  -- Train the MLP
  putStrLn ""
  trained <- trainMNIST 20 0.001
  putStrLn "[Training complete]"
