{-# LANGUAGE ScopedTypeVariables #-}

-- | MNIST raw data loader
-- Lives in data/mnist/ alongside the raw IDX files and CSV.
-- Parses IDX binary → CSV, and loads CSV → [ImagePairRow]
module MNIST_Loader
  ( loadTable,
    loadLabels,
    loadImages,
    mnistTable,
    mnistImages,
    mnistLabels,
  )
where

import C_NonLogical.A_Signature.MNIST_Sig (ImagePairRow (..))
import Data.Bits (shiftL, (.|.))
import qualified Data.ByteString as BS
import Data.Word (Word8)
import System.IO.Unsafe (unsafePerformIO)
import Torch hiding (take)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Tensor (Tensor, toDevice)

------------------------------------------------------
-- IDX binary format parsing
------------------------------------------------------

readInt32 :: [Word8] -> Int
readInt32 [a, b, c, d] =
  fromIntegral a `shiftL` 24
    .|. fromIntegral b `shiftL` 16
    .|. fromIntegral c `shiftL` 8
    .|. fromIntegral d
readInt32 _ = error "readInt32: need exactly 4 bytes"

-- | Load images → Tensor [n, 784], normalized to [0,1]
loadImages :: FilePath -> IO Tensor
loadImages path = do
  bs <- BS.readFile path
  let bytes = BS.unpack bs
      nImages = readInt32 (Prelude.take 4 (drop 4 bytes))
      pixels = drop 16 bytes
      floats = map (\w -> fromIntegral w / 255.0 :: Float) pixels
  pure $ reshape [nImages, 784] (asTensor floats)

-- | Load labels → [Int]
loadLabels :: FilePath -> IO [Int]
loadLabels path = do
  bs <- BS.readFile path
  let bytes = BS.unpack bs
      lbls = drop 8 bytes
  pure $ map fromIntegral lbls

------------------------------------------------------
-- CSV loading
------------------------------------------------------

-- | Load addition_table.csv → [ImagePairRow]
loadTable :: FilePath -> IO [ImagePairRow]
loadTable path = do
  contents <- readFile path
  let rows = tail (lines contents)
  pure [parseRow r | r <- rows, not (null r)]
  where
    parseRow line =
      let parts = map strip (splitOn ',' line)
       in ImagePairRow (read (parts !! 0)) (read (parts !! 1)) (read (parts !! 2))
    splitOn c s = case break (== c) s of
      (a, []) -> [a]
      (a, _ : rest) -> a : splitOn c rest
    strip = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')

------------------------------------------------------
-- Pre-loaded globals
------------------------------------------------------

{-# NOINLINE mnistTable #-}
mnistTable :: [ImagePairRow]
mnistTable = unsafePerformIO (loadTable "B_Interpretation/D_NonLogical/data/mnist/addition_table_30k.csv")

{-# NOINLINE mnistImages #-}
mnistImages :: Tensor
mnistImages = unsafePerformIO $ do
  imgs <- loadImages "B_Interpretation/D_NonLogical/data/mnist/train-images-idx3-ubyte"
  return (toDevice (Device MPS 0) imgs)

{-# NOINLINE mnistLabels #-}
mnistLabels :: [Int]
mnistLabels = unsafePerformIO (loadLabels "B_Interpretation/D_NonLogical/data/mnist/train-labels-idx1-ubyte")
