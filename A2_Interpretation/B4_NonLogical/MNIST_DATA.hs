{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE TypeFamilies #-}

-- | MNIST — interpretation in (DATA, Dist)
module A2_Interpretation.B4_NonLogical.MNIST_DATA where

import A1_Syntax.B4_NonLogical.MNIST_Vocab
  ( ImagePairRow (..),
    MNIST_Vocab (..),
  )
import A2_Interpretation.B1_Categorical.Monads.Dist (Dist (..))
import A2_Interpretation.B2_Typological.Categories.DATA (DATA (..))
import Numeric.Natural (Natural)

------------------------------------------------------
-- Data instance
------------------------------------------------------

mnistTable :: [ImagePairRow]
mnistTable =
  [ ImagePairRow "img_0" "img_1" 8,
    ImagePairRow "img_2" "img_3" 3,
    ImagePairRow "img_4" "img_5" 11
  ]

------------------------------------------------------
-- instance MNIST_Vocab DATA
------------------------------------------------------

instance MNIST_Vocab DATA where
  type Image DATA = String
  type Digit DATA = Natural
  type Nat DATA = Natural
  type M DATA = Dist

  digit :: Image DATA -> M DATA (Digit DATA)
  digit path = undefined -- TODO: link (h (enc path))

  add :: (Image DATA, Image DATA) -> Nat DATA
  add (x, y) =
    sumLabel $
      head
        [r | r <- mnistTable, im1 r == x, im2 r == y]
