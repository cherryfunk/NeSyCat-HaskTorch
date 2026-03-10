-- | Dice domain -- Signature + Interpretation
module B_Interpretation.C_NonLogical.Dice where

import A_Syntax.C_NonLogical.Dice_Vocab (DieResult)
import C_Semantics.A_Categorical.Monads.Dist (Dist (..))

------------------------------------------------------
-- I: Interpretation (Schema Instance + Function Definitions)
------------------------------------------------------

-- | I(die) : mFun -- uniform distribution over {1,...,6}
die :: Dist DieResult
die = Dist [(i, 1.0 / 6.0) | i <- [1 .. 6]]
