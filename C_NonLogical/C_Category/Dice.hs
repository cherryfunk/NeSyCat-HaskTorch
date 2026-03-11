-- | Dice domain -- Signature + Interpretation
module C_NonLogical.C_Category.Dice where

import C_NonLogical.A_Signature.Dice_Sig (DieResult)
import A_Categorical.C_Category.Monads.Dist (Dist (..))

------------------------------------------------------
-- I: Interpretation (Schema Instance + Function Definitions)
------------------------------------------------------

-- | I(die) : mFun -- uniform distribution over {1,...,6}
die :: Dist DieResult
die = Dist [(i, 1.0 / 6.0) | i <- [1 .. 6]]
