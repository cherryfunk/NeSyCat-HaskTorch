{-# LANGUAGE TypeApplications #-}

module Main where

import A1_Syntax.B4_NonLogical.Binary_Vocab (Binary_Vocab (classifierA, labelA))
import A2_Interpretation.B1_Categorical.Monads.Giry (Giry (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import A2_Interpretation.B2_Typological.Categories.TENS (TENS (..))
import A2_Interpretation.B3_Logical.Tensor (Omega, neg, otimes, wedge, bigWedge)
import A2_Interpretation.B4_NonLogical.Binary_MLP (Binary_MLP)
import A3_Semantics.B4_NonLogical.Binary_Training (trainBinary)
import Data.Functor.Identity (Identity (..), runIdentity)
import qualified Torch
import Torch.Typed.Tensor (Tensor (..))

-- | The pure logical axiom, interpreted via the Semantic TENS Category.
--
--   (∀_{x | label(x)}^μ.  A(x))  ⊗  (∀_{x | ¬label(x)}^μ.  ¬A(x))
--
--   where μ = empirical measure (training data).
--
--   This IS a conditional expectation:
--     bigWedge dom μ guard φ  =  1 − pMean_μ( (1−φ) | guard )
--     = 1 − ( E_μ[ guard · (1−φ)^p ] / E_μ[ guard ] )^(1/p)
axiom :: Torch.Tensor -> Binary_MLP -> Omega
axiom dataTensor m =
  bigWedge TensorSpace mu mask  pred'            -- ∀_{x | label(x)}^μ.  A(x)
  `otimes`
  bigWedge TensorSpace mu (neg . mask) (neg . pred')  -- ∀_{x | ¬label(x)}^μ.  ¬A(x)
  where
    mu    = Pure (UnsafeMkTensor dataTensor)     -- empirical measure μ = training data
    mask  x = runIdentity (labelA @TENS x)
    pred' x = runIdentity (classifierA @TENS m x)

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
