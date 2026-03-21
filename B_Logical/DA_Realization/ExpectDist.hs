{-# LANGUAGE GADTs #-}

-- | Integration for the Dist monad (finitely supported distributions).
--   Direct weighted summation — no DATA/FDATA witness needed.
module B_Logical.DA_Realization.ExpectDist
  ( expectDist,
    pTrueDist,
  )
where

import A_Categorical.D_Vocabulary.StarVocab (Dist (..))
import A_Categorical.DA_Realization.Dist ()

-- | Expectation over Dist: E_d[f] = Σ p_i · f(x_i).
--   Handles the free monad structure (Pure, Bind).
expectDist :: Dist a -> (a -> Double) -> Double
expectDist (Pure x) f = f x
expectDist (Bind m k) f = expectDist m (\x -> expectDist (k x) f)
expectDist (FiniteSupp xs) f = sum [p * f x | (x, p) <- xs]
expectDist (FinUniform xs) f = expectDist (FiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f

-- | P(True) for Dist: canonical isomorphism Dist(Bool) → [0,1].
pTrueDist :: Dist Bool -> Double
pTrueDist m = expectDist m (\b -> if b then 1.0 else 0.0)
