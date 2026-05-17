#!/usr/bin/env -S ts-node

const WIDTH = 50;
const HEIGHT = 30;
const DENSITY = 0.2;

type Grid = boolean[][];

function initializeGrid(): Grid {
  return Array.from({ length: HEIGHT }, () =>
    Array.from({ length: WIDTH }, () => Math.random() < DENSITY),
  );
}

function countNeighbors(grid: Grid, x: number, y: number): number {
  let count = 0;

  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      if (dx === 0 && dy === 0) continue;

      const nx = (x + dx + WIDTH) % WIDTH;
      const ny = (y + dy + HEIGHT) % HEIGHT;
      if (grid[ny][nx]) count++;
    }
  }

  return count;
}

function computeNextState(grid: Grid): Grid {
  return Array.from({ length: HEIGHT }, (_, y) =>
    Array.from({ length: WIDTH }, (_, x) => {
      const alive = grid[y][x];
      const neighbors = countNeighbors(grid, x, y);
      return (alive && (neighbors === 2 || neighbors === 3)) || (!alive && neighbors === 3);
    }),
  );
}

function printGrid(grid: Grid): void {
  console.clear();
  console.log(grid.map((row) => row.map((cell) => (cell ? "█" : " ")).join("")).join("\n"));
}

let grid = initializeGrid();

setInterval(() => {
  printGrid(grid);
  grid = computeNextState(grid);
}, 100);
