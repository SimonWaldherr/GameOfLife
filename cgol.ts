#!/usr/bin/env ts-node

const WIDTH = 50;
const HEIGHT = 30;
const DENSITY = 0.2;

function initializeGrid(): boolean[][] {
    const grid: boolean[][] = [];
    for (let y = 0; y < HEIGHT; y++) {
        const row: boolean[] = [];
        for (let x = 0; x < WIDTH; x++) {
            row.push(Math.random() < DENSITY);
        }
        grid.push(row);
    }
    return grid;
}

function countNeighbors(grid: boolean[][], x: number, y: number): number {
    let count = 0;
    for (const dx of [-1, 0, 1]) {
        for (const dy of [-1, 0, 1]) {
            if (dx === 0 && dy === 0) continue;
            const nx = (x + dx + WIDTH) % WIDTH;
            const ny = (y + dy + HEIGHT) % HEIGHT;
            if (grid[ny][nx]) count++;
        }
    }
    return count;
}

function computeNextState(grid: boolean[][]): boolean[][] {
    const newGrid: boolean[][] = [];
    for (let y = 0; y < HEIGHT; y++) {
        const row: boolean[] = [];
        for (let x = 0; x < WIDTH; x++) {
            const alive = grid[y][x];
            const neighbors = countNeighbors(grid, x, y);
            row.push(alive ? (neighbors === 2 || neighbors === 3) : neighbors === 3);
        }
        newGrid.push(row);
    }
    return newGrid;
}

function printGrid(grid: boolean[][]): void {
    console.log(grid.map(row => row.map(cell => (cell ? '█' : ' ')).join('')).join('\n'));
}

function main(): void {
    let grid = initializeGrid();
    setInterval(() => {
        printGrid(grid);
        grid = computeNextState(grid);
        console.log('\x1b[H\x1b[2J');
    }, 100);
}

main();
