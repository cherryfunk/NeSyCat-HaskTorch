{-# LANGUAGE GADTs #-}

-- | Integration for the Giry monad (general probability measures).
--   Dispatches on DATA objects to choose integration strategy.
module B_Logical.DA_Realization.ExpectGiry
  ( expectGiry,
    pTrueGiry,
  )
where

import A_Categorical.D_Vocabulary.StarVocab (Giry (..))
import A_Categorical.DA_Realization.Giry ()
import C_Domain.A_Category.Data (DATA (..))
import Numeric.Tools.Integration (QuadParam (..), defQuad, quadBestEst, quadRes, quadRomberg)
import Statistics.Distribution (ContDistr (density, quantile), DiscreteDistr (probability), Mean (mean), Variance (stdDev))
import qualified Statistics.Distribution.Beta as B
import qualified Statistics.Distribution.Exponential as E
import qualified Statistics.Distribution.Gamma as G
import qualified Statistics.Distribution.Geometric as Geo
import qualified Statistics.Distribution.Laplace as L
import qualified Statistics.Distribution.Normal as N
import qualified Statistics.Distribution.Poisson as Poi
import qualified Statistics.Distribution.StudentT as T
import qualified Statistics.Distribution.Uniform as U

-- | Expectation over Giry: E_giry[f], dispatched by DATA object.
expectGiry :: DATA a -> Giry a -> (a -> Double) -> Double
expectGiry _ (GPure x) f = f x
expectGiry obj (GBind m k) f = evalBind m (\x -> expectGiry obj (k x) f)
-- Reals: continuous integration
expectGiry Reals (GFiniteSupp _) _ = error "Giry: FiniteSupp on Reals -- use Normal, Uniform, GenericCont, etc."
expectGiry Reals giry f = evalContinuous giry f
-- Countably infinite: chained convergence
expectGiry Integers (GFiniteSupp xs) f = chainedDiscreteStrategy xs f
expectGiry Strings (GFiniteSupp xs) f = chainedDiscreteStrategy xs f
-- Finite: direct summation
expectGiry Booleans (GFiniteSupp xs) f = sum [p * f x | (x, p) <- xs]
expectGiry (Finite _) (GFiniteSupp xs) f = sum [p * f x | (x, p) <- xs]
expectGiry Unit _ f = f ()
expectGiry (Prod _ _) (GFiniteSupp xs) f = sum [p * f x | (x, p) <- xs]
-- FinUniform: desugar
expectGiry obj (GFinUniform xs) f = expectGiry obj (GFiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f
-- Poisson/Geometric
expectGiry _ (Poisson lambda) f = chainedDiscreteStrategy [(k, probability (Poi.poisson lambda) k) | k <- [0 ..]] f
expectGiry _ (Geometric p) f = chainedDiscreteStrategy [(k, probability (Geo.geometric0 p) k) | k <- [0 ..]] f
expectGiry _ _ _ = error "expectGiry: unsupported Giry constructor for this DATA object"

-- | P(True) for Giry: canonical isomorphism Giry(Bool) -> [0,1].
pTrueGiry :: Giry Bool -> Double
pTrueGiry m = expectGiry Booleans m (\b -> if b then 1.0 else 0.0)

------------------------------------------------------
-- INTERNAL: Generic Bind evaluator
------------------------------------------------------

evalBind :: Giry x -> (x -> Double) -> Double
evalBind (GPure x) f = f x
evalBind (GBind m k) f = evalBind m (\x -> evalBind (k x) f)
evalBind (GFiniteSupp xs) f = chainedDiscreteStrategy xs f
evalBind (Normal mu sigma) f =
  evalBind (GenericCont (N.normalDistr mu sigma)) f
evalBind (Uniform a b) f =
  evalBind (GenericCont (U.uniformDistr a b)) f
evalBind (Exponential lambda) f =
  evalBind (GenericCont (E.exponential lambda)) f
evalBind (Beta alpha beta) f =
  evalBind (GenericCont (B.betaDistr alpha beta)) f
evalBind (Gamma shape scale) f =
  evalBind (GenericCont (G.gammaDistr shape scale)) f
evalBind (Laplace loc scale) f =
  evalBind (GenericCont (L.laplace loc scale)) f
evalBind (StudentT ndf) f =
  let dist = T.studentT ndf
      lower = quantile dist 1e-15
      upper = quantile dist (1 - 1e-15)
   in integrateNT (\x -> density dist x * f x) (lower, upper)
evalBind (GenericCont dist) f =
  let trueMin = quantile dist 0.0
      trueMax = quantile dist 1.0
      lower = max trueMin (mean dist - 12 * stdDev dist)
      upper = min trueMax (mean dist + 12 * stdDev dist)
   in integrateNT (\x -> density dist x * f x) (lower, upper)
evalBind (ContinuousPdf pdf (a, b)) f =
  integrateNT (\x -> pdf x * f x) (a, b)
evalBind (GFinUniform xs) f = evalBind (GFiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f
evalBind (Poisson lambda) f = chainedDiscreteStrategy [(k, probability (Poi.poisson lambda) k) | k <- [0 ..]] f
evalBind (Geometric p) f = chainedDiscreteStrategy [(k, probability (Geo.geometric0 p) k) | k <- [0 ..]] f

------------------------------------------------------
-- INTERNAL: Continuous distribution evaluator
------------------------------------------------------

evalContinuous :: Giry Double -> (Double -> Double) -> Double
evalContinuous (Normal mu sigma) f =
  evalContinuous (GenericCont (N.normalDistr mu sigma)) f
evalContinuous (Uniform a b) f =
  evalContinuous (GenericCont (U.uniformDistr a b)) f
evalContinuous (Exponential lambda) f =
  evalContinuous (GenericCont (E.exponential lambda)) f
evalContinuous (Beta alpha beta) f =
  evalContinuous (GenericCont (B.betaDistr alpha beta)) f
evalContinuous (Gamma shape scale) f =
  evalContinuous (GenericCont (G.gammaDistr shape scale)) f
evalContinuous (Laplace loc scale) f =
  evalContinuous (GenericCont (L.laplace loc scale)) f
evalContinuous (StudentT ndf) f =
  let dist = T.studentT ndf
      lower = quantile dist 1e-15
      upper = quantile dist (1 - 1e-15)
   in integrateNT (\x -> density dist x * f x) (lower, upper)
evalContinuous (GenericCont dist) f =
  let trueMin = quantile dist 0.0
      trueMax = quantile dist 1.0
      lower = max trueMin (mean dist - 12 * stdDev dist)
      upper = min trueMax (mean dist + 12 * stdDev dist)
   in integrateNT (\x -> density dist x * f x) (lower, upper)
evalContinuous (ContinuousPdf pdf (a, b)) f =
  integrateNT (\x -> pdf x * f x) (a, b)
evalContinuous giry f = evalBind giry f

------------------------------------------------------
-- Discrete convergence strategies
------------------------------------------------------

giryMaxDiscreteIter :: Int
giryMaxDiscreteIter = 10000

chainedDiscreteStrategy :: [(a, Double)] -> (a -> Double) -> Double
chainedDiscreteStrategy xs f =
  case algebraicSimplify xs f of
    Just exactVal -> exactVal
    Nothing ->
      let go _ _ acc [] = acc
          go iter pSum acc ((x, p) : rest)
            | pSum >= 1.0 - giryQuadPrecision = acc + p * f x
            | iter >= giryMaxDiscreteIter =
                acc + p * f x + stridedMonteCarlo rest (pSum + p) f
            | otherwise = go (iter + 1) (pSum + p) (acc + p * f x) rest
       in go 0 0.0 0.0 xs

algebraicSimplify :: [(a, Double)] -> (a -> Double) -> Maybe Double
algebraicSimplify xs f =
  let numTerms = 10
      terms = take numTerms [p * f x | (x, p) <- xs]
      checkGeometric ts
        | length ts < numTerms = Nothing
        | otherwise =
            let (a : b : rest) = ts
             in if abs a < 1e-14
                  then Nothing
                  else
                    let r = b / a
                        isGeometric _ [] = True
                        isGeometric prev (curr : rs)
                          | abs prev < 1e-14 = False
                          | abs ((curr / prev) - r) < 1e-9 = isGeometric curr rs
                          | otherwise = False
                     in if abs r < (1.0 - 1e-9) && isGeometric b rest
                          then Just (a / (1.0 - r))
                          else Nothing
   in checkGeometric terms

stridedMonteCarlo :: [(a, Double)] -> Double -> (a -> Double) -> Double
stridedMonteCarlo tailXs pSumStart f =
  let stride = 50
      maxSamples = 100
      go [] acc _ _ = acc
      go xs acc pSum samples
        | pSum >= 1.0 - giryQuadPrecision = acc
        | samples >= maxSamples =
            let remainingMass = 1.0 - pSum
                avgValue = if pSum > pSumStart then acc / (pSum - pSumStart) else 0.0
             in acc + (remainingMass * avgValue)
        | otherwise =
            case splitAt stride xs of
              ([], _) -> acc
              (block, rest) ->
                let (sampleX, _) = head block
                    blockMass = sum (map snd block)
                 in go rest (acc + blockMass * f sampleX) (pSum + blockMass) (samples + 1)
   in go tailXs 0.0 pSumStart 0

------------------------------------------------------
-- Continuous integration (Lebesgue / Romberg)
------------------------------------------------------

giryQuadMaxIter :: Int
giryQuadMaxIter = 16

giryQuadPrecision :: Double
giryQuadPrecision = 1e-12

integrateNT :: (Double -> Double) -> (Double, Double) -> Double
integrateNT f (a, b) =
  let customQuad = defQuad {quadMaxIter = giryQuadMaxIter, quadPrecision = giryQuadPrecision}
      res = quadRomberg customQuad (a, b) f
   in case quadRes res of
        Just v -> v
        Nothing -> quadBestEst res
