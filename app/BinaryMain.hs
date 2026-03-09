{-# LANGUAGE TypeApplications #-}

module Main where

import A1_Syntax.B4_NonLogical.Binary_Vocab (Binary_Vocab (classifierA, labelA))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import A2_Interpretation.B3_Logical.TensUniform
    ( negU, bigWedgeU, Omega, wedge )
import A2_Interpretation.B4_NonLogical.Binary_MLP (Binary_MLP)
import A3_Semantics.B4_NonLogical.Binary_Training (trainBinary)
import Data.Functor.Identity (Identity (..), runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | The pure logical axiom, interpreted via the Semantic TENS Category.
--
--   (∀_{x | label(x)}^unif.  A(x))  ∧  (∀_{x | ¬label(x)}^unif.  ¬A(x))
--
--   Uses TensUniform: optimized quantifiers for finite uniform measures.
--   MLP and labelA evaluated ONCE, cached as BatchOmega, reused.
axiom :: Torch.Tensor -> Binary_MLP -> Omega
axiom dataTensor m =
  let pt     = UnsafeMkTensor dataTensor
      preds  = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      forallPos = bigWedgeU labels preds
      forallNeg = bigWedgeU (negU labels) (negU preds)
   in forallPos `wedge` forallNeg

main :: IO ()
main = do
  putStrLn "Starting Binary Classification LTS Evaluation Native"
  _ <- trainBinary 1000 0.001 axiom

  putStrLn "\n--- Inference Test using DATA Category (Encoder + Decoder) ---"
  let pt1 = [0.5, 0.5] :: [Float]
  let pt2 = [0.9, 0.9] :: [Float]

  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2

  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."

