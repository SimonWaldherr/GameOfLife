#!/usr/bin/env node

const WIDTH = 50;
const HEIGHT = 30;
const DENSITY = 0.2;
let grid = initializeGrid();

function initializeGrid() {
    let grid = [];
    for (let y = 0; y < HEIGHT; y++) {
        let row = [];
        for (let x = 0; x < WIDTH; x++) {
            row.push(Math.random() < DENSITY);
        }
        grid.push(row);
    }
    return grid;
}

function countNeighbors(grid, x, y) {
    let count = 0;
    for (let dx of [-1, 0, 1]) {
        for (let dy of [-1, 0, 1]) {
            if (dx === 0 && dy === 0) continue;
            let nx = (x + dx + WIDTH) % WIDTH;
            let ny = (y + dy + HEIGHT) % HEIGHT;
            if (grid[ny][nx]) count++;
        }
    }
    return count;
}

function computeNextState(grid) {
    let newGrid = [];
    for (let y = 0; y < HEIGHT; y++) {
        let row = [];
        for (let x = 0; x < WIDTH; x++) {
            let alive = grid[y][x];
            let neighbors = countNeighbors(grid, x, y);
            row.push(alive ? (neighbors === 2 || neighbors === 3) : neighbors === 3);
        }
        newGrid.push(row);
    }
    return newGrid;
}

function printGrid(grid) {
    console.clear();
    console.log(grid.map(row => row.map(cell => (cell ? '█' : ' ')).join('')).join('\n'));
}

setInterval(() => {
    printGrid(grid);
    grid = computeNextState(grid);
}, 100);