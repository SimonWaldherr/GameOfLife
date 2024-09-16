//usr/bin/env go run $0 $@ ; exit

package main

import (
	"fmt"
	"math/rand"
	"time"
)

const (
	width   = 50  // Width of the grid
	height  = 30  // Height of the grid
	density = 0.2 // Probability that a cell starts alive
)

// initializeGrid creates a 2D grid with random initial alive (true) or dead (false) cells
func initializeGrid() [][]bool {
	grid := make([][]bool, height)
	for y := range grid {
		grid[y] = make([]bool, width)
		for x := range grid[y] {
			// Each cell is alive based on the density constant
			grid[y][x] = rand.Float64() < density
		}
	}
	return grid
}

// countNeighbors counts the number of live neighbors around a given cell (x, y)
// It uses modulo to wrap around the grid edges (toroidal structure)
func countNeighbors(grid [][]bool, x, y int) int {
	count := 0
	for dx := -1; dx <= 1; dx++ {
		for dy := -1; dy <= 1; dy++ {
			if dx == 0 && dy == 0 {
				// Skip the current cell itself
				continue
			}
			// Calculate neighbor coordinates with wrap-around using modulo
			nx := (x + dx + width) % width
			ny := (y + dy + height) % height
			if grid[ny][nx] {
				count++
			}
		}
	}
	return count
}

// computeNextState calculates the next generation of the grid based on the Game of Life rules
// It returns a new grid instead of modifying the existing one
func computeNextState(grid [][]bool) [][]bool {
	newGrid := make([][]bool, height) // Allocate memory for the new grid
	for y := range newGrid {
		newGrid[y] = make([]bool, width)
		for x := range newGrid[y] {
			alive := grid[y][x]
			neighbors := countNeighbors(grid, x, y)

			// Apply Game of Life rules:
			// - Any live cell with 2 or 3 live neighbors survives.
			// - Any dead cell with exactly 3 live neighbors becomes alive.
			// - All other live cells die in the next generation.
			newGrid[y][x] = (alive && neighbors == 2) || neighbors == 3
		}
	}
	return newGrid
}

// printGrid displays the grid in the console using "█" for alive cells and " " for dead cells
func printGrid(grid [][]bool) {
	for _, row := range grid {
		for _, cell := range row {
			if cell {
				fmt.Print("█") // Alive cell
			} else {
				fmt.Print(" ") // Dead cell
			}
		}
		fmt.Println()
	}
}

func main() {
	grid := initializeGrid() // Initialize the grid with random live/dead cells
	for {
		printGrid(grid)                    // Print the current state of the grid
		grid = computeNextState(grid)      // Compute the next generation
		time.Sleep(100 * time.Millisecond) // Wait 100ms between generations for visualization

		// Clear the terminal screen for the next frame (ANSI escape codes)
		fmt.Print("\033[H\033[2J")
	}
}
