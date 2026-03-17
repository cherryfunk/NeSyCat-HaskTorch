{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | beta-parameter optimization for TensReal logic.
--
--   Lives in B_Logical/E_Parameters because beta is a LOGICAL parameter
--   (it controls /\, \/, forall, exists sharpness), independent of any non-logical
--   model parameters (theta = MLP weights).
--
--   Provides:
--     • stepBeta:     single gradient-based beta update
--     • trainBetaOnly: beta-only optimization loop (theta frozen)
module B_Logical.G_Parameters.BetaTrainingReal
  ( stepBeta,
    trainBetaOnly,
  )
where

import B_Logical.F_Interpretation.TensReal (Omega)
import C_NonLogical.F_Interpretation.BinaryRealMLP (Binary_MLP)
import Text.Printf (printf)
import qualified Torch
import Torch.Autograd (IndependentTensor, makeIndependent, toDependent)
import Torch.Typed.Tensor (toDynamic)

-- | One beta-optimization step via manual SGD on the gradient.
--
--   Given a loss tensor (scalar, with grad graph attached),
--   compute d(loss)/d(beta) and update: beta <- beta - lr * d(loss)/d(beta)
--   Then clamp beta > eps to keep it positive.
stepBeta :: IndependentTensor -> Torch.Tensor -> Float -> IO IndependentTensor
stepBeta betaInd lossTensor lr = do
  let grads = Torch.grad lossTensor [betaInd]
      gradBeta = head grads
      betaDep = toDependent betaInd
      lrT = Torch.asTensor lr
      newBeta = betaDep `Torch.sub` (gradBeta `Torch.mul` lrT)
      -- Clamp beta > 0.01 to stay positive: relu(beta - eps) + eps
      epsT = Torch.asTensor (0.01 :: Float)
      clamped = Torch.relu (newBeta `Torch.sub` epsT) `Torch.add` epsT
  makeIndependent clamped

-- | Train beta only (theta frozen).
--
--   Takes a formula  f :: beta -> data -> model -> Omega,
--   a frozen model, training data, and optimizes beta over numEpochs.
--   Returns the final learned beta value.
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
