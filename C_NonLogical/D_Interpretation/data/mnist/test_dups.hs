import Data.List

main :: IO ()
main = do
  contents <- readFile "addition_table_30k.csv"
  let rows = tail (lines contents)
  let pairs = [(head p, p !! 1) | r <- rows, let p = words (map (\c -> if c == ',' then ' ' else c) r)]
  print $ length pairs
  print $ length (nub pairs)
