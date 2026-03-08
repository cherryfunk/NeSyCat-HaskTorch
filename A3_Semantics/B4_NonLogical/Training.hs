-- | MNIST Addition — Training loop (top row: Tens, Id)
--
-- Everything is tensors here. The Dist monad is not used during training.
-- Autograd flows through: softmax(h_θ(enc(img))) → formula → loss → backward.
module A3_Semantics.B4_NonLogical.Training where

import Torch (Tensor)

------------------------------------------------------
-- Formula evaluation (all tensor ops)
------------------------------------------------------

-- | P(digit(x) + digit(y) = n) as a tensor scalar.
--   sum_{d1+d2=n} p1[d1] * p2[d2]
mnistAddProb :: Tensor -> Tensor -> Int -> Tensor
mnistAddProb p1 p2 n = undefined

-- TODO: p1, p2 are softmax outputs (Tensor [10])
-- index pairs where d1+d2=n, multiply, sum

------------------------------------------------------
-- Loss
------------------------------------------------------

-- | NLL loss: -log P(formula satisfied)
mnistLoss :: Tensor -> Tensor -> Int -> Tensor
mnistLoss p1 p2 n = undefined

-- TODO: negate (log (mnistAddProb p1 p2 n))

------------------------------------------------------
-- Training loop
------------------------------------------------------

-- | Train the digit classifier on image pairs.
trainMNIST :: IO ()
trainMNIST = undefined

-- TODO:
-- 1. Initialize θ (random weights, requires_grad)
-- 2. For each epoch:
--    a. For each (img1, img2, sum) in mnistTable:
--       - p1 = softmax(hTheta θ (enc img1))
--       - p2 = softmax(hTheta θ (enc img2))
--       - loss = mnistLoss p1 p2 sum
--       - backward loss
--       - optimizer step
-- 3. Return trained θ*
