{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | β-parameter optimization for TensReal logic.
--
--   This module lives in D_Inference/C_Logical because β is a LOGICAL parameter
--   (it controls ∧, ∨, ∀, ∃ sharpness), independent of any non-logical
--   model parameters (θ = MLP weights).
--
--   Provides:
--     • stepBeta:     single gradient-based β update
--     • trainBetaOnly: β-only optimization loop (θ frozen)
module E_Inference.B_Logical.BetaTrainingReal
  ( stepBeta,
    trainBetaOnly,
  )
where

import B_Logical.C_Category.TensUniform (Omega)
import C_NonLogical.C_Category.BinaryRealMLP (Binary_MLP)
import Text.Printf (printf)
import qualified Torch
import Torch.Autograd (IndependentTensor, makeIndependent, toDependent)
import Torch.Typed.Tensor (toDynamic)

-- | One β-optimization step via manual SGD on the gradient.
--
--   Given a loss tensor (scalar, with grad graph attached),
--   compute ∂loss/∂β and update: β ← β − lr · ∂loss/∂β
--   Then clamp β > ε to keep it positive.
stepBeta :: IndependentTensor -> Torch.Tensor -> Float -> IO IndependentTensor
stepBeta betaInd lossTensor lr = do
  let grads = Torch.grad lossTensor [betaInd]
      gradBeta = head grads
      betaDep = toDependent betaInd
      lrT = Torch.asTensor lr
      newBeta = betaDep `Torch.sub` (gradBeta `Torch.mul` lrT)
      -- Clamp β > 0.01 to stay positive: relu(β − ε) + ε
      epsT = Torch.asTensor (0.01 :: Float)
      clamped = Torch.relu (newBeta `Torch.sub` epsT) `Torch.add` epsT
  makeIndependent clamped

-- | Train β only (θ frozen).
--
--   Takes a formula  f :: β → data → model → Omega,
--   a frozen model, training data, and optimizes β over numEpochs.
--   Returns the final learned β value.
trainBetaOnly ::
  Int ->
  Float ->
  Float ->
  (Torch.Tensor -> Torch.Tensor -> Binary_MLP -> Omega) ->
  Binary_MLP ->
  Torch.Tensor ->
  IO Torch.Tensor
trainBetaOnly numEpochs lr initBeta formula model trainData = do
  betaInd <- makeIndependent (Torch.asTensor initBeta)
  putStrLn $
    printf "[Beta-Only Training] %d epochs, lr=%.6f, init_beta=%.4f" numEpochs lr initBeta

  finalBetaInd <- foldLoopBeta betaInd [1 .. numEpochs] $ \bInd epoch -> do
    let betaVal = toDependent bInd
        kbSat = formula betaVal trainData model
        kbSatDyn = toDynamic kbSat
        loss = negate (Torch.log (Torch.sigmoid kbSatDyn))

    newBInd <- stepBeta bInd loss lr

    if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
      then do
        let lossVal = Torch.asValue loss :: Float
            currentBeta = Torch.asValue (toDependent newBInd) :: Float
        putStrLn $ printf "[Beta Epoch %3d/%d] Loss=%7.5f beta=%.6f" epoch numEpochs lossVal currentBeta
      else return ()

    return newBInd

  return (toDependent finalBetaInd)

foldLoopBeta :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoopBeta acc [] _ = return acc
foldLoopBeta acc (x : xs) f = f acc x >>= \a -> foldLoopBeta a xs f
