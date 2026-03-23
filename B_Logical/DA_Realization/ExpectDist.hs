{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Realization of QuantVocabDist: expectation under the Dist monad.
--   Dist is always finitely supported, so expectation is a weighted sum.
--   One universal instance for all types.
module B_Logical.DA_Realization.ExpectDist
  ( pTrueDist,
  )
where

import A_Categorical.D_Vocabulary.StarVocab (Dist (..))
import A_Categorical.DA_Realization.Dist ()
import B_Logical.D_Vocabulary.QuantifierVocab (QuantVocabDist (..))

-- | Universal instance: Dist is always finitely supported.
--   E_d[f] = Sum p_i * f(x_i).
instance QuantVocabDist a where
  expectDist (Pure x) f = f x
  expectDist (Bind m k) f = expectDist m (\x -> expectDist (k x) f)
  expectDist (FiniteSupp xs) f = sum [p * f x | (x, p) <- xs]
  expectDist (FinUniform xs) f = expectDist (FiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f

-- | P(True) for Dist: canonical isomorphism Dist(Bool) -> [0,1].
pTrueDist :: Dist Bool -> Double
pTrueDist m = expectDist m (\b -> if b then 1.0 else 0.0)
