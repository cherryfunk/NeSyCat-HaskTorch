{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Main where

-- \$\mathcal{I}_\Upsilon$: Logical interpretation (Product logic)

-- \$\mathcal{I}_\Sigma$: Domain-specific interpretations

import C_NonLogical.A_Signature.MNIST_Sig (ImagePairRow (..), MNIST_Vocab (Digit, Image, M, add, digit, digitEq, digitPlus))
import D_Grammatical.A_Signature.FormulasSig (loadFormulas)
import B_Logical.C_Category.DATA (DATA (..))
import B_Logical.C_Category.Boolean
import C_NonLogical.C_Category.Countable
import C_NonLogical.C_Category.Crossing
import C_NonLogical.C_Category.Dice
import C_NonLogical.C_Category.MNIST (mnistTable)
import C_NonLogical.C_Category.Weather
import A_Categorical.C_Category.Monads.Dist (Dist)
import A_Categorical.C_Category.Monads.Expectation (HasExpectation (..), probDist, probGiry)
import A_Categorical.C_Category.Monads.Giry (Giry)
import Data.List (isPrefixOf)
import qualified Data.Map as Map
import Numeric.Natural (Natural)
import System.Environment (getArgs)

------------------------------------------------------

------------------------------------------------------
-- 1. DICE (Dist monad)
------------------------------------------------------
dieSen1 :: Dist Omega
dieSen1 = do
  x <- die
  return (x .== 6 `wedge` b2o (even x))

dieExp1 :: Double
dieExp1 = probDist dieSen1

dieSen2 :: Dist Omega
dieSen2 = do
  p <- do x <- die; return (x .== 6)
  q <- do x <- die; return (b2o (even x))
  return (p `wedge` q)

dieExp2 :: Double
dieExp2 = probDist dieSen2

------------------------------------------------------
-- 2. CROSSING (Dist monad) -- Uller paper
--    "For every crossing, only continue driving if there is a green light."
--    $\forall x \in X(l := \text{traffic\_light}(x),\; d := \text{car}(x, l))\;(\neg\text{true}(d) \vee l = \text{green})$
--    still missing the universal quantifier
------------------------------------------------------
crossingSen :: Dist Omega
crossingSen = do
  l <- lightDetector
  d <- drivingDecision l
  return (neg (d .== 1) `vee` l .== "Green")

crossingExp :: Double
crossingExp = probDist crossingSen

------------------------------------------------------
-- 3. WEATHER (Giry monad) - DeepSeaProbLog paper
------------------------------------------------------

-- | Weather scenario 1: "it is humid AND hot (t > 30)"
weatherSen1 :: Giry Omega
weatherSen1 = do
  h <- bernoulli (humidDetect data1)
  t <- normalDist (tempPredict data1)
  return (h .== 1 `wedge` t .> 30.0)

weatherExp1 :: Double
weatherExp1 = probGiry weatherSen1

-- | Weather scenario 2: "it is humid AND warm (t > 25)"
weatherSen2 :: Giry Omega
weatherSen2 = do
  h <- bernoulli (humidDetect data1)
  t <- normalDist (tempPredict data1)
  return (h .== 1 `wedge` t .> 25.0)

weatherExp2 :: Double
weatherExp2 = probGiry weatherSen2

-- | Weather scenario 3: "it is humid AND average (t > 0)" -> P = 0.25
weatherSen3 :: Giry Omega
weatherSen3 = do
  h <- bernoulli (humidDetect data3)
  t <- normalDist (tempPredict data3)
  return (h .== 1 `wedge` t .> 0.0)

weatherExp3 :: Double
weatherExp3 = probGiry weatherSen3

-- | Natural entailment: "humid and very hot" entails "humid and warm"
weatherEntails :: Bool
weatherEntails = probGiry weatherSen1 <= probGiry weatherSen2

------------------------------------------------------
-- 4. COUNTABLE SETS (Giry monad)
------------------------------------------------------
countableSen1 :: Giry Omega
countableSen1 = do
  x <- drawInt
  y <- drawStr
  return (x .> 3 `wedge` b2o (isPrefixOf "TT" y))

countableExp1 :: Double
countableExp1 = probGiry countableSen1

countableSenLazy :: Giry Omega
countableSenLazy = do
  x <- drawLazy
  return (b2o (even x))

countableExpLazy :: Double
countableExpLazy = probGiry countableSenLazy

countableSenHeavy :: Giry Omega
countableSenHeavy = do
  x <- drawHeavy
  return top

countableExpHeavy :: Double
countableExpHeavy = probGiry countableSenHeavy

------------------------------------------------------
-- 5. MNIST Addition (DATA, Dist)
--    ∀(x,y) ∈ table. digitEq (digitPlus (digit x) (digit y)) (add (x,y))
------------------------------------------------------
mnistSen :: Dist Omega
mnistSen = bigWedgeM (Finite mnistTable) $ \r -> do
  dx <- digit @DATA (im1 r)
  dy <- digit @DATA (im2 r)
  return (if digitEq @DATA (digitPlus @DATA dx dy) (add @DATA (im1 r, im2 r)) then top else bot)

mnistExp1 :: Double
mnistExp1 = probDist mnistSen

------------------------------------------------------
-- EXECUTION
------------------------------------------------------
main :: IO ()
main = do
  args <- getArgs
  case args of
    ["baseline"] -> return ()
    ["E_Benchmark-weather"] -> do
      print weatherExp1
    ["E_Benchmark-countable"] -> do
      print countableExp1
    ["E_Benchmark-countable-lazy"] -> do
      print countableExpLazy
    ["E_Benchmark-countable-heavy"] -> do
      print countableExpHeavy
    _ -> do
      putStrLn "-- Testing mULLER Framework (SHALLOW, Product Logic) --"

      forms <- loadFormulas "../ULLER_paper/4. NeSyCat Theory/Conference Paper/nesycat-resources.tex"
      let getF name = Map.findWithDefault name name forms

      putStrLn $ "\n[DICE] " ++ getF "fDiceOne"
      print dieExp1

      putStrLn $ "\n[DICE] " ++ getF "fDiceTwo"
      print dieExp2

      putStrLn $ "\n[CROSSING] " ++ getF "fCrossing"
      print crossingExp

      putStrLn $ "\n[WEATHER 1 - Berlin] " ++ getF "fWeatherOne"
      print weatherExp1

      putStrLn $ "\n[WEATHER 2 - Hamburg] " ++ getF "fWeatherTwo"
      print weatherExp2

      putStrLn $ "\n[WEATHER 3 - Bremen] " ++ getF "fWeatherThree"
      print weatherExp3

      putStrLn "\n[WEATHER] Berlin entails Hamburg?"
      print weatherEntails

      putStrLn $ "\n[COUNTABLE] " ++ getF "fCountable"
      print countableExp1

      putStrLn "\n[MNIST] digit(0) + digit(1) == add(0,1)"
      print mnistExp1
