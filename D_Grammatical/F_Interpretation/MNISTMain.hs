{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Grammatical interpretation: MNIST digit addition evaluation.
module Main where

import C_Domain.D_Theory.MnistTheory (ImagePairRow (..))
import C_Domain.A_Category.Data (DATA (..))
import C_Domain.F_Interpretation.MNIST (mnistTable)
import C_Domain.G_Parameters.MNIST_Training (trainMNIST)
import D_Grammatical.D_Theory.MnistFormulas (mnistPredicate, mnistSen)
import A_Categorical.F_Interpretation.Monads.Expectation (probDist)

main :: IO ()
main = do
  putStrLn $ "[MNIST] Table size: " ++ show (length mnistTable) ++ " pairs"

  let total = fromIntegral (length mnistTable) :: Double

  -- Train the MLP for 20 Epochs
  putStrLn "\n[Start Training]"
  _trained <- trainMNIST 20 0.001
  putStrLn "[Training complete]"

  -- Re-evaluate the exact same logic formula natively substituting the new optimized parameters
  let finalExp = probDist (mnistSen ())
  let finalAcc = sum (map (probDist . mnistPredicate) mnistTable) / total
  putStrLn $ "\n[MNIST TRAINED DATA] forall P(formula) = " ++ show finalExp
  putStrLn $ "[MNIST TRAINED DATA] Accuracy = " ++ show finalAcc
