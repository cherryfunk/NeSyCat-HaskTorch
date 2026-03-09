{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | JIT E_Benchmark: traces the axiom forward pass, compares JIT vs eager.
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
import B_Interpretation.D_NonLogical.Binary_MLP_Real (Binary_MLP (..), binarySpecReal)
import B_Interpretation.D_NonLogical.Binary_Real ()
import Data.Functor.Identity (Identity (..), runIdentity)
import Data.IORef
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..), replaceParameters, sample)
import qualified Torch
import Torch.Autograd (IndependentTensor (..), toDependent)
import Torch.Device (Device (..), DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Script
  ( IValue (..),
    ScriptModule,
    dumpToStr',
    runMethod1,
    toScriptModule,
    trace,
  )
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | The eager axiom (same as BinaryMain).
axiomEager :: Torch.Tensor -> Binary_MLP -> Omega
axiomEager dataTensor m =
  let pt = UnsafeMkTensor dataTensor
      preds = toDynamic (runIdentity (classifierA @TENS m pt))
      labels = toDynamic (runIdentity (labelA @TENS pt))
      negLabels = Torch.onesLike labels - labels
      forallPos = bigWedgeR labels preds
      forallNeg = bigWedgeR negLabels (negR preds)
   in UnsafeMkTensor (toDynamic forallPos `wedgeR` toDynamic forallNeg)

-- | Create a detached copy of a model by wrapping detached tensors
--   as IndependentTensors directly (bypassing makeIndependent which
--   sets requires_grad=True).
detachModel :: Binary_MLP -> IO Binary_MLP
detachModel m = do
  let params = flattenParameters m
  detachedTensors <- mapM (Torch.detach . toDependent) params
  let noGradParams = map IndependentTensor detachedTensors
  return $ replaceParameters m noGradParams

-- | Trace the axiom: parameters baked as constants (no grad).
traceAxiom :: Binary_MLP -> Torch.Tensor -> IO ScriptModule
traceAxiom model trainData = do
  dm <- detachModel model
  rawMod <- trace "axiom" "forward" (forwardFn dm) [trainData]
  toScriptModule rawMod
  where
    forwardFn dm [d] = do
      let sat = axiomEager d dm
          satDyn = toDynamic sat
          loss = Torch.onesLike satDyn `Torch.sub` satDyn
      return [loss]
    forwardFn _ _ = error "traceAxiom: expected 1 input"

main :: IO ()
main = do
  putStrLn "=== JIT Compilation Test ==="

  -- Setup
  initModel <- return . Torch.toDevice (Device CPU 0) =<< sample binarySpecReal
  dataset <- Torch.toDevice (Device CPU 0) <$> Torch.randIO' [100, 2]
  let center = F.mulScalar (Torch.onesLike dataset) 0.5
      diffs = dataset - center
      sq = diffs * diffs
      distances = Torch.sumDim (Torch.Dim 1) Torch.RemoveDim Torch.Float sq
      labelsBool = distances `Torch.lt` F.mulScalar (Torch.onesLike distances) 0.09
      labels = Torch.toType Torch.Float labelsBool
      trainData = Torch.sliceDim 0 0 50 1 dataset

  -- Test 1: Trace
  putStrLn "\n[1] Tracing axiom with detached (no-grad) model..."
  scriptMod <- traceAxiom initModel trainData
  putStrLn "[1] Trace successful!"

  dump <- dumpToStr' scriptMod
  putStrLn $ "[1] Graph:\n" ++ dump

  -- Test 2: Run JIT
  putStrLn "\n[2] Running traced module..."
  let result = runMethod1 scriptMod "forward" (IVTensor trainData)
  case result of
    IVTensor t -> putStrLn $ "[2] JIT loss = " ++ show (Torch.asValue t :: Float)
    _ -> putStrLn $ "[2] Unexpected return type"

  -- Test 3: Eager
  putStrLn "\n[3] Eager comparison..."
  let eagerSat = axiomEager trainData initModel
      eagerLoss = 1.0 - (Torch.asValue (toDynamic eagerSat) :: Float)
  putStrLn $ "[3] Eager loss = " ++ show eagerLoss

  -- Test 4: Benchmark
  putStrLn "\n[4] Benchmarking (10000 iters)..."

  ref <- newIORef (0.0 :: Float)
  t0 <- getCurrentTime
  mapM_
    ( \_ -> do
        let s = axiomEager trainData initModel
            !v = Torch.asValue (toDynamic s) :: Float
        writeIORef ref v
    )
    [1 .. 10000 :: Int]
  t1 <- getCurrentTime
  eagerVal <- readIORef ref
  let eagerTime = realToFrac (diffUTCTime t1 t0) :: Double
  printf "[4] Eager: %.4f ms/iter (last=%.4f)\n" (eagerTime * 1000.0 / 10000.0) eagerVal

  ref2 <- newIORef (0.0 :: Float)
  t2 <- getCurrentTime
  mapM_
    ( \_ -> do
        case runMethod1 scriptMod "forward" (IVTensor trainData) of
          IVTensor t -> writeIORef ref2 (Torch.asValue t :: Float)
          _ -> return ()
    )
    [1 .. 10000 :: Int]
  t3 <- getCurrentTime
  jitVal <- readIORef ref2
  let jitTime = realToFrac (diffUTCTime t3 t2) :: Double
  printf "[4] JIT:   %.4f ms/iter (last=%.4f)\n" (jitTime * 1000.0 / 10000.0) jitVal
  printf "[4] Speedup: %.2fx\n" (eagerTime / jitTime)
