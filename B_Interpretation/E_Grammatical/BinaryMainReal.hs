{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import A_Syntax.D_NonLogical.Binary_Vocab (Binary_Vocab (classifierA, labelA))
import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.C_Logical.TensReal
  ( Omega,
    bigWedgeR,
    negR,
    wedgeR,
  )
-- instance import
import B_Interpretation.D_NonLogical.Binary_MLP_Real (Binary_MLP, hThetaReal)
import B_Interpretation.D_NonLogical.Binary_Real ()
import D_Inference.D_NonLogical.Binary_Training_Real (trainBinaryReal)
import Data.Functor.Identity (Identity (..), runIdentity)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import Torch (Parameterized (..), replaceParameters)
import qualified Torch
import Torch.Autograd (IndependentTensor (..), toDependent)
import Torch.Script
  ( IValue (..),
    ScriptModule,
    runMethod1,
    toScriptModule,
    trace,
  )
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | The pure logical axiom (TensReal).
axiom :: Torch.Tensor -> Binary_MLP -> Omega
axiom dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      negLabels = Torch.onesLike labels - labels
      forallPos = bigWedgeR labels preds
      forallNeg = bigWedgeR negLabels (negR preds)
   in UnsafeMkTensor (toDynamic forallPos `wedgeR` toDynamic forallNeg)

-- | Detach model parameters for JIT tracing.
detachModel :: Binary_MLP -> IO Binary_MLP
detachModel m = do
  let params = flattenParameters m
  detachedTensors <- mapM (Torch.detach . toDependent) params
  let noGradParams = map IndependentTensor detachedTensors
  return $ replaceParameters m noGradParams

-- | Trace the MLP forward pass for JIT evaluation.
traceHTheta :: Binary_MLP -> Torch.Tensor -> IO ScriptModule
traceHTheta model exampleInput = do
  dm <- detachModel model
  rawMod <- trace "hTheta" "forward" (fwdFn dm) [exampleInput]
  toScriptModule rawMod
  where
    fwdFn dm [x] = return [Torch.sigmoid (hThetaReal dm x)]
    fwdFn _ _ = error "traceHTheta: expected 1 input"

-- | Run JIT forward pass.
runJit :: ScriptModule -> Torch.Tensor -> Torch.Tensor
runJit sm input = case runMethod1 sm "forward" (IVTensor input) of
  IVTensor t -> t
  _ -> error "runJit: unexpected IValue"

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensReal Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryReal 1000 0.001 axiom

  -- === EAGER evaluation ===
  putStrLn "\n=== EAGER Evaluation ==="
  evaluateMetrics (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels (Torch.sigmoid (hThetaReal finalModel testData)) testLabels

  -- === JIT evaluation ===
  putStrLn "\n=== JIT Compiled Evaluation ==="
  jitModule <- traceHTheta finalModel trainData
  let jitTrainProbs = runJit jitModule trainData
      jitTestProbs = runJit jitModule testData
  evaluateMetrics jitTrainProbs trainLabels jitTestProbs testLabels

  -- === Numerical diff ===
  let eagerTrainProbs = Torch.sigmoid (hThetaReal finalModel trainData)
      eagerTestProbs = Torch.sigmoid (hThetaReal finalModel testData)
      diffTrain = Torch.asValue (Torch.sumAll (Torch.abs (eagerTrainProbs - jitTrainProbs))) :: Float
      diffTest = Torch.asValue (Torch.sumAll (Torch.abs (eagerTestProbs - jitTestProbs))) :: Float
  putStrLn $ "\n=== Numerical Diff (Eager vs JIT) ==="
  putStrLn $ "  Sum|eager-jit| train: " ++ show diffTrain
  putStrLn $ "  Sum|eager-jit| test:  " ++ show diffTest

  putStrLn "\n--- Inference Test using DATA Category (Encoder + Decoder) ---"
  let pt1 = [0.5, 0.5] :: [Float]
  let pt2 = [0.9, 0.9] :: [Float]
  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2
  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."
