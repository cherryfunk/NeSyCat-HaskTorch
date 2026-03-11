-- | Crossing domain -- Signature + Interpretation (Ola paper, Fig. 1)
--
-- "For every crossing, only continue driving if there is a green light."
--  $\forall x \in X(l := \text{traffic\_light}(x),\; d := \text{car}(x, l))\;(\neg\text{true}(d) \vee l = \text{green})$
module C_NonLogical.D_Interpretation.Crossing where

import C_NonLogical.A_Signature.Crossing_Sig (Decision, LightColor)
import A_Categorical.D_Interpretation.Monads.Dist (Dist (..))

------------------------------------------------------
-- I: Interpretation (Schema Instance + Function Definitions)
------------------------------------------------------

-- | I(traffic_light) : mFun -- light detector (conditional distribution over colors)
--   P(Red) = 0.6, P(Orange) = 0.1, P(Green) = 0.3
lightDetector :: Dist LightColor
lightDetector = Dist [("Red", 0.6), ("Orange", 0.1), ("Green", 0.3)]

-- | I(car) : mFun -- driving decision (conditional on light color)
--   P(go | Red) = 0.1, P(go | Orange) = 0.2, P(go | Green) = 0.9
drivingDecision :: LightColor -> Dist Decision
drivingDecision "Red" = Dist [(0, 0.9), (1, 0.1)]
drivingDecision "Orange" = Dist [(0, 0.8), (1, 0.2)]
drivingDecision "Green" = Dist [(0, 0.1), (1, 0.9)]
drivingDecision _ = Dist [(0, 1.0)]
