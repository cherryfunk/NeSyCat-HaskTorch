-- | Dice domain -- Signature + Interpretation
module C_Domain.BA_Interpretation.Dice where

import C_Domain.B_Theory.DiceTheory (DieResult)
import A_Categorical.DA_Realization.Dist (Dist (..))

------------------------------------------------------
-- I: Interpretation (Schema Instance + Function Definitions)
------------------------------------------------------

-- | I(die) : mFun -- uniform distribution over {1,...,6}
die :: Dist DieResult
die = FiniteSupp [(i, 1.0 / 6.0) | i <- [1 .. 6]]
