#!/usr/bin/env awk -f
#
# cgol.awk: Conway's Game of Life in AWK
#
# Grid size and initial live-cell density
BEGIN {
    width = 50
    height = 30
    density = 0.2  # 20% chance a cell is alive

    srand()  # Seed the random number generator

    # Initialize the grid with random live (1) or dead (0) cells.
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            idx = y * width + x
            grid[idx] = (rand() < density) ? 1 : 0
        }
    }

    # Hide the cursor (ANSI escape code)
    printf "\033[?25l"

    # Main simulation loop
    while (1) {
        print_grid()         # Display the current grid state
        compute_next_state() # Compute the next generation

        # Copy new_grid into grid for the next iteration
        for (i in new_grid) {
            grid[i] = new_grid[i]
        }
        delete new_grid  # Clear new_grid for reuse

        # Pause for 100ms (adjust if necessary)
        system("sleep 0.1")

        # Clear the screen (move cursor to top-left and clear display)
        printf "\033[H\033[2J"
    }
}

# print_grid: Outputs the grid using "█" for live cells and " " for dead cells.
function print_grid(   output, y, x, idx) {
    output = ""
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            idx = y * width + x
            output = output (grid[idx] == 1 ? "█" : " ")
        }
        output = output "\n"
    }
    printf "%s", output
}

# compute_next_state: Calculates the next generation using the Game of Life rules.
# The grid is treated as toroidal so neighbors wrap around the edges.
function compute_next_state(   x, y, idx, dx, dy, nx, ny, nidx, count) {
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            idx = y * width + x
            count = 0
            # Count live neighbors in the 8 surrounding cells
            for (dx = -1; dx <= 1; dx++) {
                for (dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0)
                        continue  # Skip the cell itself
                    nx = (x + dx + width) % width
                    ny = (y + dy + height) % height
                    nidx = ny * width + nx
                    count += grid[nidx]
                }
            }
            # Apply Conway's rules:
            # - A live cell with 2 or 3 neighbors survives.
            # - A dead cell with exactly 3 neighbors becomes alive.
            # - Otherwise, the cell dies or remains dead.
            if ((grid[idx] == 1 && (count == 2 || count == 3)) || (grid[idx] == 0 && count == 3))
                new_grid[idx] = 1
            else
                new_grid[idx] = 0
        }
    }
}

END {
    # On exit, show the cursor again
    printf "\033[?25h"
}

