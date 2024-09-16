//go:build js && wasm

package main

import (
    "math/rand"
    "syscall/js"
    "time"
)

// Configuration variables
var (
    cellSize    = 10          // Size of each cell in pixels
    density     = 0.2         // Probability that a cell starts alive
    aliveColor  = "lime"      // Color of alive cells
    deadColor   = "#000000"   // Color of dead cells (currently not used)
    fps         = 10          // Frames per second
)

// Variables for grid dimensions and state
var (
    width, height int          // Grid dimensions
    grid          [][]bool     // The simulation grid
    canvas        js.Value     // Canvas DOM element
    ctx           js.Value     // Canvas rendering context
)

func main() {
    // Seed the random number generator
    rand.Seed(time.Now().UnixNano())

    // Get references to the DOM and window objects
    document := js.Global().Get("document")
    window := js.Global().Get("window")

    // Get the canvas element by ID
    canvas = document.Call("getElementById", "gameCanvas")
    ctx = canvas.Call("getContext", "2d")

    // Initialize the canvas and grid
    initialize()

    // Set up an event listener for window resize to adjust the canvas and grid
    window.Call("addEventListener", "resize", js.FuncOf(func(this js.Value, args []js.Value) interface{} {
        initialize()
        return nil
    }))

    // Start the simulation loop
    go startSimulation()

    // Prevent the Go program from exiting
    select {}
}

// initialize sets up the canvas size and initializes the grid
func initialize() {
    // Get the window dimensions
    window := js.Global().Get("window")
    canvasWidth := window.Get("innerWidth").Int()
    canvasHeight := window.Get("innerHeight").Int()

    // Resize the canvas to fill the window
    canvas.Set("width", canvasWidth)
    canvas.Set("height", canvasHeight)

    // Calculate the grid dimensions based on the canvas size and cell size
    width = canvasWidth / cellSize
    height = canvasHeight / cellSize

    // Initialize the grid with random alive cells
    grid = initializeGrid()
}

// initializeGrid creates a grid of specified dimensions with random alive cells
func initializeGrid() [][]bool {
    newGrid := make([][]bool, height)
    for y := 0; y < height; y++ {
        row := make([]bool, width)
        for x := 0; x < width; x++ {
            // Randomly set cells to alive based on the density
            row[x] = rand.Float64() < density
        }
        newGrid[y] = row
    }
    return newGrid
}

// countNeighbors counts the number of alive neighbors around a cell at (x, y)
func countNeighbors(grid [][]bool, x, y int) int {
    count := 0
    // Loop through neighboring cells
    for dy := -1; dy <= 1; dy++ {
        for dx := -1; dx <= 1; dx++ {
            // Skip the current cell
            if dx == 0 && dy == 0 {
                continue
            }
            // Calculate neighbor coordinates with wrapping (toroidal grid)
            nx := (x + dx + width) % width
            ny := (y + dy + height) % height
            if grid[ny][nx] {
                count++
            }
        }
    }
    return count
}

// computeNextState calculates the next generation of the grid
func computeNextState(grid [][]bool) [][]bool {
    newGrid := make([][]bool, height)
    for y := 0; y < height; y++ {
        row := make([]bool, width)
        for x := 0; x < width; x++ {
            alive := grid[y][x]
            neighbors := countNeighbors(grid, x, y)
            // Apply Game of Life rules
            if alive {
                row[x] = neighbors == 2 || neighbors == 3
            } else {
                row[x] = neighbors == 3
            }
        }
        newGrid[y] = row
    }
    return newGrid
}

// drawGrid renders the grid onto the canvas
func drawGrid(grid [][]bool) {
    // Clear the canvas
    ctx.Call("clearRect", 0, 0, canvas.Get("width").Int(), canvas.Get("height").Int())
    // Set the fill style for alive cells
    ctx.Set("fillStyle", aliveColor)
    // Loop through the grid cells
    for y := 0; y < height; y++ {
        for x := 0; x < width; x++ {
            if grid[y][x] {
                // Draw alive cells
                ctx.Call("fillRect", x*cellSize, y*cellSize, cellSize, cellSize)
            }
        }
    }
}

// startSimulation runs the game loop at a specified frames per second
func startSimulation() {
    ticker := time.NewTicker(time.Duration(1000/fps) * time.Millisecond)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            grid = computeNextState(grid)
            drawGrid(grid)
        }
    }
}
