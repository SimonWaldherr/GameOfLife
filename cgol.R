#!/usr/bin/env Rscript

# Constants for the grid size and density of alive cells
width <- 50
height <- 30
density <- 0.2

# Function to initialize the grid with random alive or dead cells
initializeGrid <- function() {
  grid <- matrix(runif(width * height) < density, nrow = height, ncol = width)
  return(grid)
}

# Function to count the number of alive neighbors around a given cell
countNeighbors <- function(grid, x, y) {
  # Neighbor shifts to cover all surrounding cells
  shifts <- expand.grid(dx = -1:1, dy = -1:1)
  shifts <- shifts[!(shifts$dx == 0 & shifts$dy == 0), ] # Remove the current cell
  
  count <- 0
  
  for (i in 1:nrow(shifts)) {
    nx <- (x + shifts$dx[i] - 1) %% width + 1
    ny <- (y + shifts$dy[i] - 1) %% height + 1
    if (grid[ny, nx]) {
      count <- count + 1
    }
  }
  
  return(count)
}

# Function to compute the next state of the grid based on the Game of Life rules
computeNextState <- function(grid) {
  newGrid <- matrix(FALSE, nrow = height, ncol = width)
  
  for (y in 1:height) {
    for (x in 1:width) {
      alive <- grid[y, x]
      neighbors <- countNeighbors(grid, x, y)
      
      # Apply Game of Life rules
      newGrid[y, x] <- (alive && neighbors == 2) || neighbors == 3
    }
  }
  
  return(newGrid)
}

# Function to print the grid to the console
printGrid <- function(grid) {
  for (y in 1:height) {
    for (x in 1:width) {
      if (grid[y, x]) {
        cat("█")  # Print alive cell
      } else {
        cat(" ")  # Print dead cell
      }
    }
    cat("\n")
  }
}

# Main execution loop
grid <- initializeGrid()  # Initialize the grid

repeat {
  printGrid(grid)          # Print the current grid
  grid <- computeNextState(grid)  # Compute the next generation
  Sys.sleep(0.1)           # Pause for 100 milliseconds

  # Clear the screen
  cat("\033[H\033[2J")
}
