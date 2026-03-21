{-# LANGUAGE TypeApplications #-}

-- | Grammatical theory: MNIST digit addition formulas (Dist monad).
module D_Grammatical.B_Theory.MnistFormulas
  ( mnistPredicate,
    mnistSen,
  )
where

import A_Categorical.DA_Realization.Dist (Dist)
import B_Logical.BA_Interpretation.Boolean hiding (Omega)
import C_Domain.C_TypeSystem.Data (DATA)
import C_Domain.B_Theory.MnistTheory (ImagePairRow (..), MnistTheory (..))
import C_Domain.BA_Interpretation.MNIST (mnistTable)

-- | Single-row predicate: digitEq (digitPlus (digit x) (digit y)) (add (x,y))
mnistPredicate :: ImagePairRow -> Dist (Omega DATA)
mnistPredicate r = do
  dx <- digit @DATA (im1 r)
  dy <- digit @DATA (im2 r)
  return (digitEq @DATA (digitPlus @DATA dx dy) (add @DATA (im1 r, im2 r)))

-- | Full axiom: forall (x,y). digitEq (digitPlus (digit x) (digit y)) (add (x,y))
--   Functional getter to prevent Haskell memoizing the initial untrained distribution.
mnistSen :: () -> Dist (Omega DATA)
mnistSen () = bigWedgeM (Finite mnistTable) mnistPredicate
