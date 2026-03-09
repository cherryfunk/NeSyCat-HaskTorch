{-# LANGUAGE TypeApplications #-}

module Main where

import A1_Syntax.B4_NonLogical.Binary_Vocab (Binary_Vocab (classifierA, labelA))
import A2_Interpretation.B1_Categorical.Monads.Giry (Giry (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import A2_Interpretation.B3_Logical.Tensor (Omega, neg, wedge, bigWedgeDirect)
import A2_Interpretation.B4_NonLogical.Binary_MLP (Binary_MLP)
import A3_Semantics.B4_NonLogical.Binary_Training (trainBinary)
import Data.Functor.Identity (Identity (..), runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..))

-- | The pure logical axiom, interpreted via the Semantic TENS Category.
--
--   (∀_{x | label(x)}^μ.  A(x))  ∧  (∀_{x | ¬label(x)}^μ.  ¬A(x))
--
--   OPTIMIZED: MLP and labelA are evaluated ONCE, results cached and reused
--   for both quantifiers. Uses bigWedgeDirect to skip expectTENS lambdas.
axiom :: Torch.Tensor -> Binary_MLP -> Omega
axiom dataTensor m =
  let pt      = UnsafeMkTensor dataTensor
      -- Cache: evaluate MLP and labels exactly ONCE
      preds   = runIdentity (classifierA @TENS m pt)   -- h_θ(x) for all x
      labels  = runIdentity (labelA @TENS pt)          -- label(x) for all x
      -- Reuse cached tensors for both quantifiers
      forallPos = bigWedgeDirect labels preds               -- ∀_{x|label}. A(x)
      forallNeg = bigWedgeDirect (neg labels) (neg preds)   -- ∀_{x|¬label}. ¬A(x)
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
