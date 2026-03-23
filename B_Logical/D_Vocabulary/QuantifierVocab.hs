-- | Quantifier vocabulary: abstract symbols for quantifier reduction.
--
--   These are the "raw symbols" -- named by what they ARE.
--   Realization (DA_Realization/) provides the implementations.
--   The interpretation (BA_Interpretation/) picks from these.
--
--   Four symbols, split into two classes:
--     QuantVocabLattice: sup, inf      (lattice reduction, per domain type)
--     QuantVocabDist:    expectDist     (measure expectation, Dist monad)
--     QuantVocabGiry:    expectGiry     (measure expectation, Giry monad)
module B_Logical.D_Vocabulary.QuantifierVocab
  ( QuantVocabLattice (..),
    QuantVocabDist (..),
    QuantVocabGiry (..),
  )
where

import A_Categorical.D_Vocabulary.StarVocab (Dist, Giry)

-- | Lattice quantifier symbols: sup and inf over a domain type.
class QuantVocabLattice a where
  sup :: (a -> Double) -> Double
  inf :: (a -> Double) -> Double

-- | Measure quantifier symbol: expectation under Dist.
class QuantVocabDist a where
  expectDist :: Dist a -> (a -> Double) -> Double

-- | Measure quantifier symbol: expectation under Giry.
class QuantVocabGiry a where
  expectGiry :: Giry a -> (a -> Double) -> Double
