-- | Dice domain -- Signature + Interpretation
module C_NonLogical.F_Interpretation.Dice where

import C_NonLogical.D_Theory.DiceTheory (DieResult)
import A_Categorical.F_Interpretation.Monads.Dist (Dist (..))

------------------------------------------------------
-- I: Interpretation (Schema Instance + Function Definitions)
------------------------------------------------------

-- | I(die) : mFun -- uniform distribution over {1,...,6}
die :: Dist DieResult
die = Dist [(i, 1.0 / 6.0) | i <- [1 .. 6]]
