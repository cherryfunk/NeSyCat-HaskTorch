{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}

-- | Realization of QuantVocabGiry: expectation under the Giry monad.
--   Per-type dispatch: finite types enumerate, countable types lazy-fold,
--   continuous types use numerical integration.
module B_Logical.DA_Realization.ExpectGiry
  ( pTrueGiry,
  )
where

import A_Categorical.D_Vocabulary.StarVocab (Giry (..))
import A_Categorical.DA_Realization.Giry ()
import B_Logical.D_Vocabulary.QuantifierVocab (QuantVocabGiry (..))
import Numeric.Natural (Natural)
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

-- Finite types
expectFinite :: Giry a -> (a -> Double) -> Double
expectFinite (GPure x) f = f x
expectFinite (GBind m k) f = evalBind m (\x -> expectFinite (k x) f)
expectFinite (GFiniteSupp xs) f = sum [p * f x | (x, p) <- xs]
expectFinite (GFinUniform xs) f = expectFinite (GFiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f
expectFinite _ _ = error "expectGiry (finite): unsupported constructor"

-- Countable types
expectCountable :: Giry a -> (a -> Double) -> Double
expectCountable (GPure x) f = f x
expectCountable (GBind m k) f = evalBind m (\x -> expectCountable (k x) f)
expectCountable (GFiniteSupp xs) f = chainedDiscreteStrategy xs f
expectCountable (GFinUniform xs) f = expectCountable (GFiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f
expectCountable (Poisson lambda) f = chainedDiscreteStrategy [(k, probability (Poi.poisson lambda) k) | k <- [0 ..]] f
expectCountable (Geometric p) f = chainedDiscreteStrategy [(k, probability (Geo.geometric0 p) k) | k <- [0 ..]] f
expectCountable _ _ = error "expectGiry (countable): unsupported constructor"

-- QuantVocabGiry instances (realization of the vocabulary)
instance QuantVocabGiry Bool where expectGiry = expectFinite
instance QuantVocabGiry () where expectGiry _ f = f ()
instance QuantVocabGiry Int where expectGiry = expectFinite
instance QuantVocabGiry Char where expectGiry = expectFinite
instance (QuantVocabGiry a, QuantVocabGiry b) => QuantVocabGiry (a, b) where expectGiry = expectFinite
instance QuantVocabGiry Integer where expectGiry = expectCountable
instance QuantVocabGiry Natural where expectGiry = expectCountable

instance QuantVocabGiry Double where
  expectGiry (GPure x) f = f x
  expectGiry (GBind m k) f = evalBind m (\x -> expectGiry (k x) f)
  expectGiry (GFiniteSupp _) _ = error "Giry: FiniteSupp on Reals"
  expectGiry giry f = evalContinuous giry f

pTrueGiry :: Giry Bool -> Double
pTrueGiry m = expectGiry m (\b -> if b then 1.0 else 0.0)

-- Internal: bind evaluator
evalBind :: Giry x -> (x -> Double) -> Double
evalBind (GPure x) f = f x
evalBind (GBind m k) f = evalBind m (\x -> evalBind (k x) f)
evalBind (GFiniteSupp xs) f = chainedDiscreteStrategy xs f
evalBind (Normal mu sigma) f = evalBind (GenericCont (N.normalDistr mu sigma)) f
evalBind (Uniform a b) f = evalBind (GenericCont (U.uniformDistr a b)) f
evalBind (Exponential lambda) f = evalBind (GenericCont (E.exponential lambda)) f
evalBind (Beta alpha beta) f = evalBind (GenericCont (B.betaDistr alpha beta)) f
evalBind (Gamma shape scale) f = evalBind (GenericCont (G.gammaDistr shape scale)) f
evalBind (Laplace loc scale) f = evalBind (GenericCont (L.laplace loc scale)) f
evalBind (StudentT ndf) f = let d = T.studentT ndf in integrateNT (\x -> density d x * f x) (quantile d 1e-15, quantile d (1-1e-15))
evalBind (GenericCont d) f = let lo = max (quantile d 0) (mean d - 12*stdDev d); hi = min (quantile d 1) (mean d + 12*stdDev d) in integrateNT (\x -> density d x * f x) (lo, hi)
evalBind (ContinuousPdf pdf (a, b)) f = integrateNT (\x -> pdf x * f x) (a, b)
evalBind (GFinUniform xs) f = evalBind (GFiniteSupp [(x, 1.0 / fromIntegral (length xs)) | x <- xs]) f
evalBind (Poisson lambda) f = chainedDiscreteStrategy [(k, probability (Poi.poisson lambda) k) | k <- [0 ..]] f
evalBind (Geometric p) f = chainedDiscreteStrategy [(k, probability (Geo.geometric0 p) k) | k <- [0 ..]] f

-- Internal: continuous evaluator
evalContinuous :: Giry Double -> (Double -> Double) -> Double
evalContinuous (Normal mu sigma) f = evalContinuous (GenericCont (N.normalDistr mu sigma)) f
evalContinuous (Uniform a b) f = evalContinuous (GenericCont (U.uniformDistr a b)) f
evalContinuous (Exponential lambda) f = evalContinuous (GenericCont (E.exponential lambda)) f
evalContinuous (Beta alpha beta) f = evalContinuous (GenericCont (B.betaDistr alpha beta)) f
evalContinuous (Gamma shape scale) f = evalContinuous (GenericCont (G.gammaDistr shape scale)) f
evalContinuous (Laplace loc scale) f = evalContinuous (GenericCont (L.laplace loc scale)) f
evalContinuous (StudentT ndf) f = let d = T.studentT ndf in integrateNT (\x -> density d x * f x) (quantile d 1e-15, quantile d (1-1e-15))
evalContinuous (GenericCont d) f = let lo = max (quantile d 0) (mean d - 12*stdDev d); hi = min (quantile d 1) (mean d + 12*stdDev d) in integrateNT (\x -> density d x * f x) (lo, hi)
evalContinuous (ContinuousPdf pdf (a, b)) f = integrateNT (\x -> pdf x * f x) (a, b)
evalContinuous giry f = evalBind giry f

-- Discrete convergence
giryMaxDiscreteIter :: Int
giryMaxDiscreteIter = 10000
giryQuadPrecision :: Double
giryQuadPrecision = 1e-12

chainedDiscreteStrategy :: [(a, Double)] -> (a -> Double) -> Double
chainedDiscreteStrategy xs f = case algebraicSimplify xs f of
  Just v -> v
  Nothing -> let go _ _ acc [] = acc
                 go i ps acc ((x,p):rest)
                   | ps >= 1-giryQuadPrecision = acc+p*f x
                   | i >= giryMaxDiscreteIter = acc+p*f x+stridedMonteCarlo rest (ps+p) f
                   | otherwise = go (i+1) (ps+p) (acc+p*f x) rest
              in go 0 0 0 xs

algebraicSimplify :: [(a,Double)] -> (a -> Double) -> Maybe Double
algebraicSimplify xs f = let n=10; ts=take n [p*f x|(x,p)<-xs]
                             chk ts' | length ts' < n = Nothing
                                     | otherwise = let (a:b:rest)=ts' in if abs a<1e-14 then Nothing
                                       else let r=b/a; isG _ []=True; isG prev (c:cs)|abs prev<1e-14=False|abs((c/prev)-r)<1e-9=isG c cs|otherwise=False
                                            in if abs r<(1-1e-9)&&isG b rest then Just(a/(1-r)) else Nothing
                          in chk ts

stridedMonteCarlo :: [(a,Double)] -> Double -> (a -> Double) -> Double
stridedMonteCarlo tl pS f = let stride=50;maxS=100
                                go [] acc _ _=acc; go xs acc ps s|ps>=1-giryQuadPrecision=acc|s>=maxS=let rm=1-ps;av=if ps>pS then acc/(ps-pS) else 0 in acc+rm*av
                                  |otherwise=case splitAt stride xs of{([],_)->acc;(bl,rest)->let(sx,_)=head bl;bm=sum(map snd bl) in go rest (acc+bm*f sx) (ps+bm) (s+1)}
                             in go tl 0 pS 0

integrateNT :: (Double -> Double) -> (Double, Double) -> Double
integrateNT f (a, b) = let cq=defQuad{quadMaxIter=16,quadPrecision=giryQuadPrecision}; res=quadRomberg cq (a,b) f
                         in case quadRes res of {Just v->v; Nothing->quadBestEst res}
