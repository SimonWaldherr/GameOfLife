#!/usr/bin/env nim r
import os, times, random

const
  width = 50
  height = 30
  density = 0.2

type
  Grid = array[height, array[width, bool]]

proc initGrid(): Grid =
  var grid: Grid
  for y in 0..<height:
    for x in 0..<width:
      grid[y][x] = rand(1.0) < density
  return grid

proc countNeighbors(grid: Grid, x, y: int): int =
  var count = 0
  for dx in -1..1:
    for dy in -1..1:
      if dx == 0 and dy == 0: continue
      let nx = (x + dx + width) mod width
      let ny = (y + dy + height) mod height
      if grid[ny][nx]:
        inc(count)
  return count

proc nextGeneration(grid: Grid): Grid =
  var newGrid: Grid
  for y in 0..<height:
    for x in 0..<width:
      let alive = grid[y][x]
      let neighbors = countNeighbors(grid, x, y)
      newGrid[y][x] = (alive and (neighbors == 2 or neighbors == 3)) or
                      ((not alive) and (neighbors == 3))
  return newGrid

proc printGrid(grid: Grid) =
  stdout.write("\x1B[H\x1B[2J")
  for row in grid:
    for cell in row:
      stdout.write(if cell: "█" else: " ")
    stdout.write("\n")

proc gameLoop(grid: Grid) =
  var current = grid
  while true:
    printGrid(current)
    sleep(100)  # 100 milliseconds
    current = nextGeneration(current)

when isMainModule:
  randomize()
  gameLoop(initGrid())
