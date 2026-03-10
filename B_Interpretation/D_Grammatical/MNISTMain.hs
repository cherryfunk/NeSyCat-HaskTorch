{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import A_Syntax.C_NonLogical.MNIST_Vocab (ImagePairRow (..), MNIST_Vocab (..), MNIST_Bridge (..))
import C_Semantics.A_Categorical.Monads.Dist (Dist (..))
import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.B_Logical.Boolean hiding (Omega)
import B_Interpretation.C_NonLogical.MNIST (mnistTable)
import B_Interpretation.C_NonLogical.MNIST_MLP (MLP, hTheta)
import D_Inference.C_NonLogical.MNIST_Training (trainMNIST)
import C_Semantics.A_Categorical.Monads.Expectation (probDist)
import qualified Torch
import Torch.Typed.Tensor (toDynamic, Tensor(UnsafeMkTensor))

------------------------------------------------------
-- MNIST Formula (DATA): ∀(x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
------------------------------------------------------

mnistPredicate :: ImagePairRow -> Dist (Omega DATA)
mnistPredicate r = do
  dx <- digit @DATA (im1 r)
  dy <- digit @DATA (im2 r)
  return (digitEq @DATA (digitPlus @DATA dx dy) (add @DATA (im1 r, im2 r)))

-- Functional getter to prevent Haskell memoizing the initial untrained distribution
mnistSen :: () -> Dist (Omega DATA)
mnistSen () = bigWedgeM (Finite mnistTable) mnistPredicate

------------------------------------------------------
-- EXECUTION
------------------------------------------------------
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
  putStrLn $ "\n[MNIST TRAINED DATA] ∀ P(formula) = " ++ show finalExp
  putStrLn $ "[MNIST TRAINED DATA] Accuracy = " ++ show finalAcc

