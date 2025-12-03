#!/usr/bin/env runhaskell

import System.Random
import Control.Concurrent (threadDelay)
import System.IO (hFlush, stdout)

width :: Int
width = 50

height :: Int
height = 30

density :: Double
density = 0.2

type Grid = [[Bool]]

initializeGrid :: IO Grid
initializeGrid = do
    gen <- getStdGen
    let randoms = randomRs (0.0, 1.0) gen :: [Double]
    return $ chunksOf width $ take (width * height) $ map (< density) randoms

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = take n xs : chunksOf n (drop n xs)

countNeighbors :: Grid -> Int -> Int -> Int
countNeighbors grid x y = length $ filter id neighbors
  where
    neighbors = [grid !! ny !! nx | dx <- [-1, 0, 1], dy <- [-1, 0, 1],
                 not (dx == 0 && dy == 0),
                 let nx = (x + dx) `mod` width,
                 let ny = (y + dy) `mod` height]

computeNextState :: Grid -> Grid
computeNextState grid = 
    [[nextCell x y | x <- [0..width-1]] | y <- [0..height-1]]
  where
    nextCell x y = 
        let alive = grid !! y !! x
            neighbors = countNeighbors grid x y
        in if alive then neighbors `elem` [2, 3] else neighbors == 3

printGrid :: Grid -> IO ()
printGrid grid = do
    putStr "\ESC[2J\ESC[H"
    mapM_ putStrLn [map (\cell -> if cell then '█' else ' ') row | row <- grid]
    hFlush stdout

main :: IO ()
main = do
    grid <- initializeGrid
    loop grid
  where
    loop grid = do
        printGrid grid
        threadDelay 100000  -- 100 ms
        loop (computeNextState grid)
