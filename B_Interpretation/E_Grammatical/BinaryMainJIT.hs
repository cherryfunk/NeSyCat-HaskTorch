{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Proof-of-concept: JIT training with backprop through traced axiom.
module Main where

import A_Syntax.D_NonLogical.Binary_Vocab (Binary_Vocab (classifierA, labelA))
import B_Interpretation.B_Typological.TENS (TENS (..))
import B_Interpretation.C_Logical.TensUniform
  ( Omega,
    bigWedgeU,
    negU,
    wedge,
  )
import B_Interpretation.D_NonLogical.Binary_MLP (Binary_MLP (..), binarySpec, hTheta)
import Data.Functor.Identity (Identity (..), runIdentity)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..), replaceParameters, sample)
import qualified Torch
import Torch.Autograd (IndependentTensor (..), makeIndependent, toDependent, grad)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Script
  ( IValue (..),
    ScriptModule,
    runMethod1,
    toScriptModule,
    trace,
  )
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Axiom forward pass as a pure function of (dataTensor, paramsTensor).
--   This is what we will trace for JIT.
axiomEager :: Torch.Tensor -> Binary_MLP -> Omega
axiomEager dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      forallPos = bigWedgeU labels preds
      forallNeg = bigWedgeU (negU labels) (negU preds)
   in forallPos `wedge` forallNeg

main :: IO ()
main = do
  putStrLn "=== JIT Backprop Proof-of-Concept ==="

  -- Create model and data
  initModel <- return . Torch.toDevice (Device CPU 0) =<< sample binarySpec
  dataset <- Torch.toDevice (Device CPU 0) <$> Torch.randIO' [100, 2]
  let center = F.mulScalar (Torch.onesLike dataset) 0.5
      diffs = dataset - center
      sq = diffs * diffs
      distances = Torch.sumDim (Torch.Dim 1) Torch.RemoveDim Torch.Float sq
      labelsBool = distances `Torch.lt` F.mulScalar (Torch.onesLike distances) 0.09
      trainData = Torch.sliceDim 0 0 50 1 dataset

  -- Step 1: Compute loss eagerly
  let eagerSat = axiomEager trainData initModel
      eagerLoss = Torch.onesLike (toDynamic eagerSat) - toDynamic eagerSat
  putStrLn $ "[EAGER] Loss = " ++ show (Torch.asValue eagerLoss :: Float)

  -- Step 2: Compute gradient eagerly
  params <- mapM makeIndependent (flattenParameters initModel)
  let indepModel = replaceParameters initModel (map IndependentTensor (map toDependent params))
      eagerSat2 = axiomEager trainData indepModel
      eagerLoss2 = Torch.onesLike (toDynamic eagerSat2) - toDynamic eagerSat2
      eagerGrads = grad eagerLoss2 (map toDependent params)
  putStrLn $ "[EAGER] Number of gradient tensors: " ++ show (length eagerGrads)
  putStrLn $ "[EAGER] Grad norm (first param): " ++ show (Torch.asValue (Torch.sumAll (Torch.abs (head eagerGrads))) :: Float)

  -- Step 3: Trace the axiom WITH gradient-enabled model
  putStrLn "\n[JIT] Tracing axiom with gradient-enabled parameters..."
  let fwdFn [d] = do
        let sat = axiomEager d initModel
            loss = Torch.onesLike (toDynamic sat) - toDynamic sat
        return [loss]
      fwdFn _ = error "expected 1 input"
  rawMod <- trace "axiom" "forward" fwdFn [trainData]
  scriptMod <- toScriptModule rawMod

  -- Step 4: Run JIT and try to get gradient
  let jitResult = runMethod1 scriptMod "forward" (IVTensor trainData)
  case jitResult of
    IVTensor jitLoss -> do
      putStrLn $ "[JIT] Loss = " ++ show (Torch.asValue jitLoss :: Float)
      -- Try getting grads through JIT output
      let jitGrads = grad jitLoss (map toDependent params)
      putStrLn $ "[JIT] Number of gradient tensors: " ++ show (length jitGrads)
      putStrLn $ "[JIT] Grad norm (first param): " ++ show (Torch.asValue (Torch.sumAll (Torch.abs (head jitGrads))) :: Float)
    _ -> putStrLn "[JIT] Unexpected return type"

  putStrLn "\nDone."
