{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import C_NonLogical.A_Signature.MNIST_Sig (ImagePairRow (..), MNIST_Vocab (..), MNIST_Bridge (..))
import A_Categorical.D_Interpretation.Monads.Dist (Dist (..))
import C_NonLogical.D_Interpretation.DATA (DATA (..))
import B_Logical.D_Interpretation.TENS (TENS (..))
import B_Logical.D_Interpretation.Boolean hiding (Omega)
import C_NonLogical.D_Interpretation.MNIST (mnistTable)
import C_NonLogical.D_Interpretation.MNIST_MLP (MLP, hTheta)
import E_Inference.C_NonLogical.MNIST_Training (trainMNIST)
import A_Categorical.D_Interpretation.Monads.Expectation (probDist)
import qualified Torch
import Torch.Typed.Tensor (toDynamic, Tensor(UnsafeMkTensor))

------------------------------------------------------
-- MNIST Formula (DATA): forall(x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
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
  putStrLn $ "\n[MNIST TRAINED DATA] forall P(formula) = " ++ show finalExp
  putStrLn $ "[MNIST TRAINED DATA] Accuracy = " ++ show finalAcc

