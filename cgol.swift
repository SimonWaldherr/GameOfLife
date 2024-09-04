#!/usr/bin/env swift

import Foundation

let width = 50
let height = 30
let density = 0.2
var shouldContinue = true

// Initialize the grid with random alive (true) or dead (false) cells
func initializeGrid() -> [[Bool]] {
    return (0..<height).map { _ in
        (0..<width).map { _ in Bool.random() && Double.random(in: 0...1) < density }
    }
}

// Count the alive neighbors of a cell at (x, y)
func countNeighbors(grid: [[Bool]], x: Int, y: Int) -> Int {
    var count = 0
    for dx in -1...1 {
        for dy in -1...1 {
            if dx == 0 && dy == 0 { continue }
            let nx = (x + dx + width) % width
            let ny = (y + dy + height) % height
            if grid[ny][nx] { count += 1 }
        }
    }
    return count
}

// Compute the next state of the grid
func computeNextState(grid: [[Bool]]) -> [[Bool]] {
    return (0..<height).map { y in
        (0..<width).map { x in
            let alive = grid[y][x]
            let neighbors = countNeighbors(grid: grid, x: x, y: y)
            return (alive && neighbors == 2) || neighbors == 3
        }
    }
}

// Print the grid to the console
func printGrid(grid: [[Bool]]) {
    for row in grid {
        print(row.map { $0 ? "█" : " " }.joined())
    }
}

// Signal handler for SIGINT (Ctrl-C)
func handleInterruptSignal(_ signal: Int32) {
    shouldContinue = false
}

// Main loop: initialize grid, update and print in a loop
func main() {
    // Set up signal handler for SIGINT (Ctrl-C)
    signal(SIGINT, handleInterruptSignal)

    var grid = initializeGrid()

    while shouldContinue {
        print("\u{001B}[2J") // Clear the console
        print("\u{001B}[H") // Move cursor to top-left corner
        printGrid(grid: grid)
        grid = computeNextState(grid: grid)
        Thread.sleep(forTimeInterval: 0.1) // 100 ms delay
    }

    print("Game Over.")
}

main()
