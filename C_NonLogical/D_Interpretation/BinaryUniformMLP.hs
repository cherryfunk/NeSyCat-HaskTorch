{-# LANGUAGE RecordWildCards #-}

-- | Binary Classification MLP (Uniform/[0,1] variant).
--   Re-uses the same Binary_MLP architecture as BinaryRealMLP.
--   The only difference: hTheta applies sigmoid (outputs probabilities in [0,1]).
module C_NonLogical.D_Interpretation.BinaryUniformMLP
  ( Binary_MLP (..),
    Binary_MLPSpec (..),
    hTheta,
    binarySpec,
  )
where

import C_NonLogical.D_Interpretation.BinaryRealMLP
  ( Binary_MLP (..),
    Binary_MLPSpec (..),
  )
import Torch (Tensor, linear)
import qualified Torch
import Torch.NN (Randomizable (..))
import qualified Torch.Functional as F

-- | h_theta : [B, 2] -> [B, 1] (probabilities in [0,1] via sigmoid)
hTheta :: Binary_MLP -> Tensor -> Tensor
hTheta Binary_MLP {..} input =
  let l1 = F.elu (1.0 :: Float) $ linear fc1 input
      l2 = F.elu (1.0 :: Float) $ linear fc2 l1
      l3 = Torch.sigmoid $ linear fc3 l2
   in l3

binarySpec :: Binary_MLPSpec
binarySpec = Binary_MLPSpec
